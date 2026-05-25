// recommend-place Edge Function
//
// Step 3: Gemini로 지역/역 키워드 추출 → Kakao Local API로 실제 장소 검색
//
// ⚠️  GEMINI_API_KEY 미설정 시 keyword = "음식점" fallback
//     KAKAO_REST_API_KEY 미설정 시 places = [] 반환 (앱 크래시 방지)
//
// Request  : POST { lat: number, lng: number, participants?: ParticipantTravel[] }
// Response : { recommendedKeyword: string, places: PlaceResult[] }
//
// PlaceResult: { placeId, name, address, lat, lng, distanceFromMidpoint }

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';

interface ParticipantTravel {
  userId: string;
  nickname: string;
  travelMinutes: number | null;
}

interface KakaoDocument {
  id: string;
  place_name: string;
  road_address_name: string;
  address_name: string;
  x: string; // lng
  y: string; // lat
  distance: string;
}

interface KakaoLocalResponse {
  documents: KakaoDocument[];
  meta: { total_count: number; is_end: boolean };
}

async function fetchGeminiKeyword(
  apiKey: string,
  lat: number,
  lng: number,
  participants: ParticipantTravel[],
): Promise<string | null> {
  const participantDesc = participants
    .filter((p) => p.travelMinutes != null)
    .map((p) => `${p.nickname}(${p.travelMinutes}분)`)
    .join(', ');

  const prompt =
    `다음 정보를 바탕으로 약속 장소를 추천해주세요.\n` +
    `중간 지점 좌표: 위도 ${lat}, 경도 ${lng}\n` +
    `참여자별 이동 시간: ${participantDesc || '정보 없음'}\n\n` +
    `이 좌표 주변의 구체적인 지하철역 이름이나 지역명 하나만 추천해주세요.\n` +
    `반드시 다음 형식으로만 답하세요: 추천장소: [지역명 또는 역 이름]\n` +
    `예시: 추천장소: 강남역`;

  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { maxOutputTokens: 50, temperature: 0.3 },
        }),
      },
    );

    if (!res.ok) {
      console.error('[recommend-place] Gemini API error:', res.status, await res.text());
      return null;
    }

    const data = await res.json() as {
      candidates?: Array<{ content: { parts: Array<{ text: string }> } }>;
    };

    const text = data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    const match = text.match(/추천장소:\s*(.+)/);
    return match?.[1]?.trim() ?? null;
  } catch (e) {
    console.error('[recommend-place] Gemini fetch failed:', e);
    return null;
  }
}

async function searchKakaoPlaces(
  apiKey: string,
  keyword: string,
  lat: number,
  lng: number,
  radius: number,
): Promise<KakaoDocument[]> {
  const params = new URLSearchParams({
    query: keyword,
    x: String(lng), // 카카오는 x=경도, y=위도
    y: String(lat),
    radius: String(radius),
    sort: 'distance',
    size: '15',
  });

  try {
    const res = await fetch(
      `https://dapi.kakao.com/v2/local/search/keyword.json?${params}`,
      { headers: { Authorization: `KakaoAK ${apiKey}` } },
    );

    if (!res.ok) {
      console.error('[recommend-place] Kakao API error:', res.status, await res.text());
      return [];
    }

    const data = await res.json() as KakaoLocalResponse;
    return data.documents;
  } catch (e) {
    console.error('[recommend-place] Kakao fetch failed:', e);
    return [];
  }
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

  let body: { lat?: number; lng?: number; participants?: ParticipantTravel[] };
  try {
    body = await req.json();
  } catch {
    return errorResponse('Invalid JSON body');
  }

  const { lat, lng, participants = [] } = body;
  if (lat == null || lng == null) {
    return errorResponse('lat and lng are required');
  }

  const geminiKey = Deno.env.get('GEMINI_API_KEY')
    ?.replace(/[^\x20-\x7E]/g, '')
    .trim();
  const kakaoKey = Deno.env.get('KAKAO_REST_API_KEY')
    ?.replace(/[^\x20-\x7E]/g, '')
    .trim();

  // Step 3a: Gemini로 지역 키워드 추출
  let keyword = '음식점';
  if (geminiKey) {
    const geminiKeyword = await fetchGeminiKeyword(geminiKey, lat, lng, participants);
    if (geminiKeyword) keyword = geminiKeyword;
  } else {
    console.warn('[recommend-place] GEMINI_API_KEY not set. Using fallback keyword.');
  }

  // Step 3b: Kakao로 장소 검색
  if (!kakaoKey) {
    console.warn('[recommend-place] KAKAO_REST_API_KEY not set. Returning empty list.');
    return jsonResponse({ recommendedKeyword: keyword, places: [] });
  }

  let docs = await searchKakaoPlaces(kakaoKey, keyword, lat, lng, 1000);

  // 결과 없으면 '음식점' + 반경 2배로 재시도
  if (docs.length === 0 && keyword !== '음식점') {
    console.warn(`[recommend-place] No results for "${keyword}". Falling back to 음식점.`);
    docs = await searchKakaoPlaces(kakaoKey, '음식점', lat, lng, 2000);
    keyword = '음식점';
  }

  const places = docs.map((doc) => ({
    placeId: doc.id,
    name: doc.place_name,
    address: doc.road_address_name || doc.address_name,
    lat: parseFloat(doc.y),
    lng: parseFloat(doc.x),
    distanceFromMidpoint: parseFloat(doc.distance),
  }));

  return jsonResponse({ recommendedKeyword: keyword, places });
});
