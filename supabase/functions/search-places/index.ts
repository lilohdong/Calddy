// search-places Edge Function
//
// 중간 지점(lat, lng) 주변 장소를 검색합니다.
// Google Maps Places API (Nearby Search)를 사용합니다.
//
// ⚠️  GOOGLE_MAPS_API_KEY 환경변수가 Supabase Vault에 설정되어 있어야 합니다.
//     미설정 시 빈 배열을 반환합니다.
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

interface GooglePlaceResult {
  place_id: string;
  name: string;
  vicinity: string;
  geometry: { location: { lat: number; lng: number } };
}

interface GooglePlacesResponse {
  status: string;
  results: GooglePlaceResult[];
  error_message?: string;
}

// Haversine 공식으로 두 좌표 간 거리(m) 계산
function haversineDistance(
  lat1: number, lng1: number,
  lat2: number, lng2: number,
): number {
  const R = 6371000; // 지구 반지름(m)
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

Deno.serve(async (req: Request) => {
  const corsResult = handleCors(req);
  if (corsResult) return corsResult;

  // JWT 인증 확인
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

  const { lat, lng, radius = 1000, keyword } = body;
  if (lat == null || lng == null) {
    return errorResponse('lat and lng are required');
  }

  const apiKey = Deno.env.get('GOOGLE_MAPS_API_KEY');
  if (!apiKey) {
    // API 키 미설정 → 빈 배열 반환 (앱이 크래시하지 않도록)
    console.warn('[search-places] GOOGLE_MAPS_API_KEY not set. Returning empty list.');
    return jsonResponse([]);
  }

  // Google Maps Places API — Nearby Search
  const params = new URLSearchParams({
    location: `${lat},${lng}`,
    radius: String(radius),
    key: apiKey,
    language: 'ko',
  });
  if (keyword) params.set('keyword', keyword);

  const gmapsUrl =
    `https://maps.googleapis.com/maps/api/place/nearbysearch/json?${params}`;

  let gmapsResponse: GooglePlacesResponse;
  try {
    const res = await fetch(gmapsUrl);
    gmapsResponse = await res.json() as GooglePlacesResponse;
  } catch (e) {
    console.error('[search-places] Google Maps API fetch failed:', e);
    return errorResponse('Failed to fetch places from Google Maps', 502);
  }

  if (
    gmapsResponse.status !== 'OK' &&
    gmapsResponse.status !== 'ZERO_RESULTS'
  ) {
    console.error('[search-places] Google Maps error:', gmapsResponse.status, gmapsResponse.error_message);
    return errorResponse(
      `Google Maps API error: ${gmapsResponse.status}`,
      502,
    );
  }

  const places = (gmapsResponse.results ?? []).map((p) => ({
    placeId: p.place_id,
    name: p.name,
    address: p.vicinity,
    lat: p.geometry.location.lat,
    lng: p.geometry.location.lng,
    distanceFromMidpoint: haversineDistance(
      lat, lng,
      p.geometry.location.lat,
      p.geometry.location.lng,
    ),
  }));

  // 거리 오름차순 정렬
  places.sort((a, b) => a.distanceFromMidpoint - b.distanceFromMidpoint);

  return jsonResponse(places);
});
