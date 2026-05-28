import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';

interface RequestBody {
  userId: string;
  type: string;
  title: string;
  body: string;
  relatedId?: string;
}

async function getGoogleAccessToken(serviceAccountJson: string): Promise<string> {
  const sa = JSON.parse(serviceAccountJson) as {
    client_email: string;
    private_key: string;
  };

  const b64url = (obj: unknown) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '');

  const now = Math.floor(Date.now() / 1000);
  const header = b64url({ alg: 'RS256', typ: 'JWT' });
  const payload = b64url({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  });
  const signingInput = `${header}.${payload}`;

  const pemBody = sa.private_key
    .replace(/-----[^-]+-----/g, '')
    .replace(/\s/g, '');
  const keyBytes = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    keyBytes,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const rawSig = new Uint8Array(
    await crypto.subtle.sign(
      'RSASSA-PKCS1-v1_5',
      cryptoKey,
      new TextEncoder().encode(signingInput),
    ),
  );
  let binary = '';
  for (let i = 0; i < rawSig.byteLength; i++) {
    binary += String.fromCharCode(rawSig[i]);
  }
  const sig = btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${signingInput}.${sig}`,
    }),
  });

  if (!tokenRes.ok) {
    throw new Error(`OAuth2 token exchange failed: ${await tokenRes.text()}`);
  }
  return (await tokenRes.json() as { access_token: string }).access_token;
}

Deno.serve(async (req: Request) => {
  const corsResult = handleCors(req);
  if (corsResult) return corsResult;

  // DB 트리거(pg_net) 전용 — service_role key로만 호출 가능
  const authHeader = req.headers.get('Authorization') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!serviceRoleKey || authHeader !== `Bearer ${serviceRoleKey}`) {
    return errorResponse('Forbidden', 403);
  }

  let body: RequestBody;
  try {
    body = await req.json() as RequestBody;
  } catch {
    return errorResponse('Invalid JSON body');
  }

  const { userId, type, title, body: msgBody, relatedId } = body;
  if (!userId || !type || !title || !msgBody) {
    return errorResponse('Missing required fields: userId, type, title, body');
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: profile, error: profileError } = await adminClient
    .from('profiles')
    .select('fcm_token, push_enabled')
    .eq('id', userId)
    .single();

  if (profileError || !profile) {
    return errorResponse('Profile not found', 404);
  }

  if (!profile.push_enabled || !profile.fcm_token) {
    return jsonResponse({ skipped: true });
  }

  const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON');
  const projectId = Deno.env.get('FIREBASE_PROJECT_ID');
  if (!serviceAccountJson || !projectId) {
    return errorResponse('Firebase not configured', 500);
  }

  let accessToken: string;
  try {
    accessToken = await getGoogleAccessToken(serviceAccountJson);
  } catch (e) {
    const msg = `FCM auth failed: ${e instanceof Error ? e.message : String(e)}`;
    console.error(msg);
    return errorResponse('FCM auth failed', 500);
  }

  const fcmUrl =
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const fcmRes = await fetch(fcmUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      message: {
        token: profile.fcm_token,
        notification: { title, body: msgBody },
        data: {
          type,
          relatedId: relatedId ?? '',
          title,
          body: msgBody,
        },
      },
    }),
  });

  if (!fcmRes.ok) {
    console.error('FCM send failed:', await fcmRes.text());
    return errorResponse('FCM send failed', 500);
  }

  return jsonResponse({ success: true });
});
