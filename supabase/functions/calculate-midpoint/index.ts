// calculate-midpoint Edge Function
//
// 약속(appointment)의 모든 참여자(creator + accepted invitees) 좌표 평균으로
// 중간 지점(lat, lng)을 계산하고 반환합니다.
//
// travelMinutes: 이동 시간 계산은 Google Maps Directions API 키 설정 후 구현 예정.
//               현재는 null 반환.
//
// Request  : POST { appointment_id: string }
// Response : { lat: number, lng: number, participants: ParticipantTravel[] }
//
// ParticipantTravel: { userId: string, nickname: string, travelMinutes: number | null }

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';

Deno.serve(async (req: Request) => {
  const corsResult = handleCors(req);
  if (corsResult) return corsResult;

  // JWT에서 호출자 확인
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return errorResponse('Authorization header missing', 401);

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  // 서비스 롤 클라이언트: RLS 우회하여 참여자 데이터 조회
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  // 호출자 인증 검증
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

  // 약속 조회 — creator_id + accepted/pending invitees
  const { data: appointment, error: apptError } = await adminClient
    .from('appointments')
    .select(`
      creator_id,
      appointment_invites (
        invitee_id,
        status
      )
    `)
    .eq('id', appointment_id)
    .single();

  if (apptError || !appointment) {
    return errorResponse('Appointment not found', 404);
  }

  // 호출자가 creator 또는 invitee인지 확인
  const inviteeIds = (appointment.appointment_invites as { invitee_id: string; status: string }[])
    .map((i) => i.invitee_id);
  const isParticipant =
    appointment.creator_id === user.id || inviteeIds.includes(user.id);
  if (!isParticipant) return errorResponse('Forbidden', 403);

  // 수락된 invitee + creator로 참여자 목록 구성
  const acceptedInviteeIds = (
    appointment.appointment_invites as { invitee_id: string; status: string }[]
  )
    .filter((i) => i.status === 'accepted' || i.status === 'pending')
    .map((i) => i.invitee_id);

  const participantIds = Array.from(
    new Set([appointment.creator_id, ...acceptedInviteeIds]),
  );

  // 참여자 프로필 조회 (home_lat, home_lng 포함)
  const { data: profiles, error: profileError } = await adminClient
    .from('profiles')
    .select('id, nickname, home_lat, home_lng')
    .in('id', participantIds);

  if (profileError || !profiles) {
    return errorResponse('Failed to fetch participant profiles', 500);
  }

  // 좌표가 설정된 참여자만으로 중간 지점 계산
  const withLocation = profiles.filter(
    (p: { home_lat: number | null; home_lng: number | null }) =>
      p.home_lat != null && p.home_lng != null,
  );

  if (withLocation.length === 0) {
    return errorResponse(
      'No participants have home location set. Please set home_lat/home_lng in profiles.',
      422,
    );
  }

  const midLat =
    withLocation.reduce((sum: number, p: { home_lat: number }) => sum + p.home_lat, 0) /
    withLocation.length;
  const midLng =
    withLocation.reduce((sum: number, p: { home_lng: number }) => sum + p.home_lng, 0) /
    withLocation.length;

  const participants = profiles.map(
    (p: { id: string; nickname: string; home_lat: number | null; home_lng: number | null }) => ({
      userId: p.id,
      nickname: p.nickname,
      // TODO: Google Maps Directions API 키 설정 후 실제 이동 시간 계산
      travelMinutes: null as number | null,
    }),
  );

  return jsonResponse({ lat: midLat, lng: midLng, participants });
});
