// calculate-midpoint Edge Function
//
// 약속(appointment)의 모든 참여자 좌표 평균으로 중간 지점을 계산하고,
// ODsay API로 각 참여자의 대중교통 이동 시간을 조회합니다.
//
// ⚠️  ODSAY_API_KEY 환경변수가 설정되어 있어야 이동 시간이 계산됩니다.
//     미설정 시 travelMinutes = null 반환 (앱은 정상 동작).
//
// Request  : POST { appointment_id: string }
// Response : { lat: number, lng: number, participants: ParticipantTravel[] }
//
// ParticipantTravel: { userId: string, nickname: string, travelMinutes: number | null }

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';

interface OdsayPath {
  info: { totalTime: number }; // 총 이동 시간(분)
}

interface OdsayResponse {
  result?: { path: OdsayPath[] };
  error?: { code: number; message: string };
}

// ODsay 대중교통 경로 탐색 — 이동 시간(분) 반환
// 실패 시 null 반환 (선택적 기능이므로 전체 응답을 막지 않음)
async function fetchTravelMinutes(
  apiKey: string,
  startLat: number,
  startLng: number,
  endLat: number,
  endLng: number,
): Promise<number | null> {
  try {
    const params = new URLSearchParams({
      SX: String(startLng), // 출발 경도
      SY: String(startLat), // 출발 위도
      EX: String(endLng),   // 도착 경도
      EY: String(endLat),   // 도착 위도
      apiKey,
    });

    const res = await fetch(
      `https://api.odsay.com/v1/api/searchPubTransPathT?${params}`,
    );
    if (!res.ok) return null;

    const data = await res.json() as OdsayResponse;

    if (data.error || !data.result?.path?.length) return null;

    // 가장 짧은 경로의 이동 시간 반환
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

  let body: { appointment_id?: string };
  try {
    body = await req.json();
  } catch {
    return errorResponse('Invalid JSON body');
  }

  const { appointment_id } = body;
  if (!appointment_id) return errorResponse('appointment_id is required');

  // 약속 + 초대 목록 조회
  const { data: appointment, error: apptError } = await adminClient
    .from('appointments')
    .select('creator_id, appointment_invites(invitee_id, status)')
    .eq('id', appointment_id)
    .single();

  if (apptError || !appointment) {
    return errorResponse('Appointment not found', 404);
  }

  // 호출자 권한 확인
  const inviteeIds = (appointment.appointment_invites as { invitee_id: string; status: string }[])
    .map((i) => i.invitee_id);
  const isParticipant =
    appointment.creator_id === user.id || inviteeIds.includes(user.id);
  if (!isParticipant) return errorResponse('Forbidden', 403);

  // 참여자 ID 목록 (creator + accepted/pending invitees)
  const activeInviteeIds = (
    appointment.appointment_invites as { invitee_id: string; status: string }[]
  )
    .filter((i) => i.status === 'accepted' || i.status === 'pending')
    .map((i) => i.invitee_id);

  const participantIds = Array.from(
    new Set([appointment.creator_id, ...activeInviteeIds]),
  );

  // 참여자 프로필 조회
  const { data: profiles, error: profileError } = await adminClient
    .from('profiles')
    .select('id, nickname, home_lat, home_lng')
    .in('id', participantIds);

  if (profileError || !profiles) {
    return errorResponse('Failed to fetch participant profiles', 500);
  }

  // 좌표가 있는 참여자만으로 중간 지점 계산
  const withLocation = profiles.filter(
    (p: { home_lat: number | null; home_lng: number | null }) =>
      p.home_lat != null && p.home_lng != null,
  );

  if (withLocation.length === 0) {
    return errorResponse(
      'No participants have home location set. Set home_lat/home_lng in profiles.',
      422,
    );
  }

  const midLat =
    withLocation.reduce((sum: number, p: { home_lat: number }) => sum + p.home_lat, 0) /
    withLocation.length;
  const midLng =
    withLocation.reduce((sum: number, p: { home_lng: number }) => sum + p.home_lng, 0) /
    withLocation.length;

  // ODsay 이동 시간 조회 (API 키 없으면 전부 null)
  const odsayKey = Deno.env.get('ODSAY_API_KEY');

  const participants = await Promise.all(
    profiles.map(async (p: { id: string; nickname: string; home_lat: number | null; home_lng: number | null }) => {
      let travelMinutes: number | null = null;

      if (odsayKey && p.home_lat != null && p.home_lng != null) {
        travelMinutes = await fetchTravelMinutes(
          odsayKey,
          p.home_lat,
          p.home_lng,
          midLat,
          midLng,
        );
      }

      return { userId: p.id, nickname: p.nickname, travelMinutes };
    }),
  );

  return jsonResponse({ lat: midLat, lng: midLng, participants });
});
