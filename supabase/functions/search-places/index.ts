// search-places Edge Function
//
// 중간 지점(lat, lng) 주변 장소를 카카오 Local API로 검색합니다.
//
// ⚠️  KAKAO_REST_API_KEY 환경변수가 설정되어 있어야 합니다.
//     미설정 시 빈 배열을 반환합니다 (앱 크래시 방지).
//
// Request  : POST { lat: number, lng: number, radius?: number, keyword?: string }
// Response : PlaceResult[]
//
// PlaceResult: {
//   placeId: string, name: string, address: string,
//   lat: number, lng: number, distanceFromMidpoint: number
// }

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';

interface KakaoDocument {
  id: string;
  place_name: string;
  road_address_name: string;
  address_name: string;
  x: string; // lng
  y: string; // lat
  distance: string; // 중심 좌표까지 거리(m) — 카카오가 직접 제공
}

interface KakaoLocalResponse {
  documents: KakaoDocument[];
  meta: { total_count: number; is_end: boolean };
}

Deno.serve(async (req: Request) => {
  const corsResult = handleCors(req);
  if (corsResult) return corsResult;

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return errorResponse('Authorization header missing', 401);

  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    },
  );
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) return errorResponse('Unauthorized', 401);

  let body: { lat?: number; lng?: number; radius?: number; keyword?: string };
  try {
    body = await req.json();
  } catch {
    return errorResponse('Invalid JSON body');
  }

  const { lat, lng, radius = 1000, keyword = '음식점' } = body;
  if (lat == null || lng == null) {
    return errorResponse('lat and lng are required');
  }

  const apiKey = Deno.env.get('KAKAO_REST_API_KEY')
    ?.replace(/[^\x20-\x7E]/g, '')  // ASCII 가시 문자만 허용 (BOM·개행·비표준 문자 제거)
    .trim();
  if (!apiKey) {
    console.warn('[search-places] KAKAO_REST_API_KEY not set. Returning empty list.');
    return jsonResponse([]);
  }

  // 카카오 키워드 장소 검색 API
  // https://developers.kakao.com/docs/latest/ko/local/dev-guide#search-by-keyword
  const params = new URLSearchParams({
    query: keyword,
    x: String(lng), // 카카오는 x=경도, y=위도
    y: String(lat),
    radius: String(radius),
    sort: 'distance', // 거리 순 정렬
    size: '15',       // 최대 15개
  });

  let kakaoData: KakaoLocalResponse;
  try {
    const res = await fetch(
      `https://dapi.kakao.com/v2/local/search/keyword.json?${params}`,
      { headers: { Authorization: `KakaoAK ${apiKey}` } },
    );
    if (!res.ok) {
      const text = await res.text();
      console.error('[search-places] Kakao API error:', res.status, text);
      return errorResponse(`Kakao API error: ${res.status}`, 502);
    }
    kakaoData = await res.json() as KakaoLocalResponse;
  } catch (e) {
    console.error('[search-places] Kakao API fetch failed:', e);
    return errorResponse('Failed to fetch places from Kakao', 502);
  }

  const places = kakaoData.documents.map((doc) => ({
    placeId: doc.id,
    name: doc.place_name,
    address: doc.road_address_name || doc.address_name,
    lat: parseFloat(doc.y),
    lng: parseFloat(doc.x),
    distanceFromMidpoint: parseFloat(doc.distance),
  }));

  return jsonResponse(places);
});
