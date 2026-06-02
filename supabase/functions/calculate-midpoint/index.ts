// calculate-midpoint Edge Function
//
// Step 1: 참여자 좌표 평균으로 초기 중간 지점 계산
// Step 2: ODsay 대중교통 시간 기반 반복 최적화 (최대 3회, 표준편차 5분 이내 수렴 시 조기 종료)
//
// ⚠️  ODSAY_API_KEY 환경변수가 설정되어 있어야 Step 2가 동작합니다.
//     미설정 시 Step 1 결과만 반환합니다 (iterationCount = 0).
//
// Request (Mode A - appointment): POST { appointment_id: string }
// Request (Mode B - direct):      POST { locations: LocationInput[] }
//   LocationInput: { userId: string, nickname: string, address: string }
//
// Response: { lat, lng, iterationCount, participants: ParticipantTravel[] }
// ParticipantTravel: { userId, nickname, travelMinutes: number | null }

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';

const MAX_ITERATIONS = 3;
const STD_DEV_THRESHOLD = 5; // 분
const STEP_FRACTIONS = [0.2, 0.1, 0.067];

interface OdsayPath {
  info: { totalTime: number };
}

interface OdsayResponse {
  result?: { path: OdsayPath[] };
  error?: { code: number; message: string };
}

interface ProfileRow {
  id: string;
  nickname: string;
  home_lat: number | null;
  home_lng: number | null;
}

interface LocationInput {
  userId: string;
  nickname: string;
  address: string;
}

interface ParticipantCoord {
  id: string;
  nickname: string;
  home_lat: number;
  home_lng: number;
}

/** 카카오 키워드 검색으로 텍스트 주소 → 좌표 변환 */
async function geocodeAddress(
  kakaoKey: string,
  address: string,
): Promise<{ lat: number; lng: number } | null> {
  const params = new URLSearchParams({ query: address, size: '1' });
  try {
    const res = await fetch(
      `https://dapi.kakao.com/v2/local/search/keyword.json?${params}`,
      { headers: { Authorization: `KakaoAK ${kakaoKey}` } },
    );
    if (!res.ok) return null;
    const data = await res.json() as { documents: Array<{ x: string; y: string }> };
    const doc = data.documents?.[0];
    if (!doc) return null;
    return { lat: parseFloat(doc.y), lng: parseFloat(doc.x) };
  } catch {
    return null;
  }
}

function calcStdDev(values: number[]): number {
  const mean = values.reduce((a, b) => a + b, 0) / values.length;
  const variance =
    values.reduce((sum, v) => sum + Math.pow(v - mean, 2), 0) / values.length;
  return Math.sqrt(variance);
}

async function fetchTravelMinutes(
  apiKey: string,
  startLat: number,
  startLng: number,
  endLat: number,
  endLng: number,
): Promise<number | null> {
  try {
    const params = new URLSearchParams({
      SX: String(startLng),
      SY: String(startLat),
      EX: String(endLng),
      EY: String(endLat),
      apiKey,
    });

    const res = await fetch(
      `https://api.odsay.com/v1/api/searchPubTransPathT?${params}`,
    );
    if (!res.ok) return null;

    const data = await res.json() as OdsayResponse;
    if (data.error || !data.result?.path?.length) return null;

    return data.result.path[0].info.totalTime;
  } catch {
    return null;
  }
}

Deno.serve(async (req: Request) => {
  const corsResult = handleCors(req);
  if (corsResult) return corsResult;

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return errorResponse('Authorization header missing', 401);

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const userClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) return errorResponse('Unauthorized', 401);

  let body: { appointment_id?: string; locations?: LocationInput[] };
  try {
    body = await req.json();
  } catch {
    return errorResponse('Invalid JSON body');
  }

  const { appointment_id, locations: directLocations } = body;

  if (!appointment_id && (!directLocations || directLocations.length === 0)) {
    return errorResponse('appointment_id or locations is required');
  }

  let withLocation: ParticipantCoord[] = [];

  // ── Mode A: appointment_id로 profiles 테이블에서 좌표 조회 ─────────────
  if (appointment_id) {
    const { data: appointment, error: apptError } = await adminClient
      .from('appointments')
      .select('creator_id, appointment_invites(invitee_id, status)')
      .eq('id', appointment_id)
      .single();

    if (apptError || !appointment) {
      return errorResponse('Appointment not found', 404);
    }

    const inviteeIds = (
      appointment.appointment_invites as { invitee_id: string; status: string }[]
    ).map((i) => i.invitee_id);

    const isParticipant =
      appointment.creator_id === user.id || inviteeIds.includes(user.id);
    if (!isParticipant) return errorResponse('Forbidden', 403);

    const activeInviteeIds = (
      appointment.appointment_invites as { invitee_id: string; status: string }[]
    )
      .filter((i) => i.status === 'accepted' || i.status === 'pending')
      .map((i) => i.invitee_id);

    const participantIds = Array.from(
      new Set([appointment.creator_id, ...activeInviteeIds]),
    );

    const { data: profiles, error: profileError } = await adminClient
      .from('profiles')
      .select('id, nickname, home_lat, home_lng')
      .in('id', participantIds);

    if (profileError || !profiles) {
      return errorResponse('Failed to fetch participant profiles', 500);
    }

    withLocation = (profiles as ProfileRow[])
      .filter((p) => p.home_lat != null && p.home_lng != null)
      .map((p) => ({ id: p.id, nickname: p.nickname, home_lat: p.home_lat!, home_lng: p.home_lng! }));

    if (withLocation.length === 0) {
      return errorResponse(
        'No participants have home location set. Set home_lat/home_lng in profiles.',
        422,
      );
    }

  // ── Mode B: locations 배열 직접 입력 → 카카오로 주소 → 좌표 변환 ────────
  } else if (directLocations && directLocations.length > 0) {
    const kakaoKey = Deno.env.get('KAKAO_REST_API_KEY')?.replace(/[^\x20-\x7E]/g, '').trim();
    if (!kakaoKey) {
      return errorResponse('KAKAO_REST_API_KEY not configured', 500);
    }

    const geocoded = await Promise.all(
      directLocations.map(async (loc) => {
        const coords = await geocodeAddress(kakaoKey, loc.address);
        return coords ? { id: loc.userId, nickname: loc.nickname, home_lat: coords.lat, home_lng: coords.lng } : null;
      }),
    );

    withLocation = geocoded.filter((p): p is ParticipantCoord => p !== null);

    if (withLocation.length === 0) {
      return errorResponse('Could not geocode any of the provided addresses', 422);
    }
  }

  // Step 1: 좌표 평균
  let midLat =
    withLocation.reduce((sum, p) => sum + p.home_lat!, 0) / withLocation.length;
  let midLng =
    withLocation.reduce((sum, p) => sum + p.home_lng!, 0) / withLocation.length;

  // Step 2: ODsay 반복 최적화
  const odsayKey = Deno.env.get('ODSAY_API_KEY')?.trim();
  let iterationCount = 0;
  const finalTravelTimes = new Map<string, number | null>();

  // 참여자 2명 이상 + API 키 있을 때만 최적화 실행 (1명이면 표준편차 계산 불가)
  if (odsayKey && withLocation.length >= 2) {
    for (let i = 0; i < MAX_ITERATIONS; i++) {
      const results = await Promise.all(
        withLocation.map(async (p) => ({
          ...p,
          travelMinutes: await fetchTravelMinutes(
            odsayKey,
            p.home_lat!,
            p.home_lng!,
            midLat,
            midLng,
          ),
        })),
      );

      for (const r of results) {
        finalTravelTimes.set(r.id, r.travelMinutes);
      }

      const validTimes = results
        .filter((r) => r.travelMinutes != null)
        .map((r) => r.travelMinutes as number);

      // 수렴 판단: 이동 없이 종료하면 iterationCount를 증가시키지 않음
      if (validTimes.length < 2 || calcStdDev(validTimes) <= STD_DEV_THRESHOLD) break;

      // 가장 오래 걸리는 참여자 방향으로 중간 지점 이동
      const slowest = results
        .filter((r) => r.travelMinutes != null)
        .reduce((max, cur) => (cur.travelMinutes! > max.travelMinutes! ? cur : max));

      midLat += (slowest.home_lat! - midLat) * STEP_FRACTIONS[i];
      midLng += (slowest.home_lng! - midLng) * STEP_FRACTIONS[i];
      iterationCount = i + 1; // 실제 이동이 발생한 횟수만 기록
    }
  }

  const participants = withLocation.map((p) => ({
    userId: p.id,
    nickname: p.nickname,
    travelMinutes: finalTravelTimes.get(p.id) ?? null,
  }));

  return jsonResponse({ lat: midLat, lng: midLng, iterationCount, participants });
});
