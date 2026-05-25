// delete-account Edge Function
//
// JWT에서 uid를 추출하여 해당 유저의 계정을 삭제합니다.
// 개인정보보호법/GDPR 대응을 위해 삭제 전 데이터를 익명화합니다.
//
// 처리 순서:
//   1. JWT → uid 확인
//   2. posts.user_id → null  (게시글 내용은 보존, 작성자만 익명화)
//   3. comments 익명화 (user_id → null, content → '[삭제된 댓글]')
//   4. events 전체 삭제 (본인 일정이므로 hard delete)
//   5. Storage 'avatars' 버킷에서 파일 삭제
//   6. auth.admin.deleteUser → profiles도 cascade 삭제됨
//
// Request  : POST (body 없음 — Authorization 헤더의 JWT에서 uid 추출)
// Response : { success: true }

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';

Deno.serve(async (req: Request) => {
  const corsResult = handleCors(req);
  if (corsResult) return corsResult;

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return errorResponse('Authorization header missing', 401);

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;

  // 1. JWT로 호출자 uid 확인
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) return errorResponse('Unauthorized', 401);

  const uid = user.id;

  // service_role 클라이언트: RLS 우회 + admin API 접근
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  try {
    // 2. posts 익명화 — 게시글 내용은 유지, 작성자 정보만 제거
    const { error: postsError } = await adminClient
      .from('posts')
      .update({ user_id: null })
      .eq('user_id', uid);
    if (postsError) throw new Error(`posts anonymize failed: ${postsError.message}`);

    // 3. comments 익명화
    const { error: commentsError } = await adminClient
      .from('comments')
      .update({ user_id: null, content: '[삭제된 댓글]' })
      .eq('user_id', uid);
    if (commentsError) throw new Error(`comments anonymize failed: ${commentsError.message}`);

    // 4. events 전체 삭제 (cascade로 appointments, appointment_invites도 처리됨)
    const { error: eventsError } = await adminClient
      .from('events')
      .delete()
      .eq('user_id', uid);
    if (eventsError) throw new Error(`events delete failed: ${eventsError.message}`);

    // 5. Storage 'avatars' 버킷 파일 삭제
    //    파일 목록 조회 후 삭제 (경로: {uid}/ 하위 전체)
    const { data: avatarFiles } = await adminClient.storage
      .from('avatars')
      .list(uid);
    if (avatarFiles && avatarFiles.length > 0) {
      const paths = avatarFiles.map((f: { name: string }) => `${uid}/${f.name}`);
      await adminClient.storage.from('avatars').remove(paths);
    }

    // 6. auth.admin.deleteUser — profiles도 FK cascade로 삭제됨
    const { error: deleteUserError } = await adminClient.auth.admin.deleteUser(uid);
    if (deleteUserError) throw new Error(`auth deleteUser failed: ${deleteUserError.message}`);

    return jsonResponse({ success: true });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error('[delete-account] Error:', message);
    return errorResponse(`Account deletion failed: ${message}`, 500);
  }
});
