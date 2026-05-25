import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const { appointment_id } = await req.json();
  if (!appointment_id) {
    return new Response(JSON.stringify({ error: 'appointment_id required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  // 1. 약속 참여자 수집 (creator + invitees)
  const { data: appointment, error: apptError } = await supabase
    .from('appointments')
    .select('creator_id, appointment_invites(invitee_id)')
    .eq('id', appointment_id)
    .single();

  if (apptError || !appointment) {
    return new Response(JSON.stringify({ error: 'appointment not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const participantIds: string[] = [
    appointment.creator_id,
    ...appointment.appointment_invites.map((i: { invitee_id: string }) => i.invitee_id),
  ];

  // 2. profiles에서 좌표 및 닉네임 조회
  const { data: profiles } = await supabase
    .from('profiles')
    .select('id, nickname, home_lat, home_lng')
    .in('id', participantIds);

  if (!profiles || profiles.length === 0) {
    return new Response(JSON.stringify({ error: 'no participants found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // 3. 좌표가 있는 참여자만 필터링 후 중간 지점 계산
  const withLocation = profiles.filter(
    (p: { home_lat: number | null; home_lng: number | null }) =>
      p.home_lat != null && p.home_lng != null,
  );

  const midLat = withLocation.reduce((sum: number, p: { home_lat: number }) => sum + p.home_lat, 0) / withLocation.length;
  const midLng = withLocation.reduce((sum: number, p: { home_lng: number }) => sum + p.home_lng, 0) / withLocation.length;

  // 4. ODsay 대중교통 소요 시간 병렬 조회
  const odsayKey = Deno.env.get('ODSAY_API_KEY')!;

  const participants = await Promise.all(
    profiles.map(async (p: { id: string; nickname: string; home_lat: number | null; home_lng: number | null }) => {
      if (p.home_lat == null || p.home_lng == null) {
        return { userId: p.id, nickname: p.nickname, travelMinutes: null };
      }
      try {
        const url = `https://api.odsay.com/v1/api/searchPubTransPath?SX=${p.home_lng}&SY=${p.home_lat}&EX=${midLng}&EY=${midLat}&apiKey=${odsayKey}`;
        const res = await fetch(url);
        const json = await res.json();
        const totalTime = json?.result?.path?.[0]?.info?.totalTime ?? null;
        return { userId: p.id, nickname: p.nickname, travelMinutes: totalTime };
      } catch {
        return { userId: p.id, nickname: p.nickname, travelMinutes: null };
      }
    }),
  );

  return new Response(
    JSON.stringify({ lat: midLat, lng: midLng, participants }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
  );
});
