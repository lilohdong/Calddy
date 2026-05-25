const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function haversineMeters(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371000;
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLng = (lng2 - lng1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * (Math.PI / 180)) *
      Math.cos(lat2 * (Math.PI / 180)) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const { lat, lng, keyword, radius = 1000 } = await req.json();
  if (lat == null || lng == null) {
    return new Response(JSON.stringify({ error: 'lat, lng required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const apiKey = Deno.env.get('GOOGLE_MAPS_API_KEY')!;
  const params = new URLSearchParams({
    location: `${lat},${lng}`,
    radius: String(radius),
    language: 'ko',
    key: apiKey,
  });
  if (keyword) params.set('keyword', keyword);

  const url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?${params}`;
  const res = await fetch(url);

  if (!res.ok) {
    return new Response(JSON.stringify({ error: 'Google Maps API error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const json = await res.json();

  if (json.status !== 'OK' && json.status !== 'ZERO_RESULTS') {
    return new Response(JSON.stringify({ error: json.status }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const results = (json.results ?? []).slice(0, 20).map((place: {
    place_id: string;
    name: string;
    vicinity: string;
    geometry: { location: { lat: number; lng: number } };
  }) => ({
    placeId: place.place_id,
    name: place.name,
    address: place.vicinity,
    lat: place.geometry.location.lat,
    lng: place.geometry.location.lng,
    distanceFromMidpoint: haversineMeters(lat, lng, place.geometry.location.lat, place.geometry.location.lng),
  }));

  results.sort((a: { distanceFromMidpoint: number }, b: { distanceFromMidpoint: number }) =>
    a.distanceFromMidpoint - b.distanceFromMidpoint,
  );

  return new Response(JSON.stringify(results), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
});
