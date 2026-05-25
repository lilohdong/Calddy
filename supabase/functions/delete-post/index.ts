// delete-post Edge Function
//
// 게시글 삭제 시 Storage 이미지와 DB 행을 서버에서 함께 삭제합니다.
//
// 처리 순서:
//   1. JWT → uid 확인
//   2. posts 테이블에서 해당 게시글 조회 (소유자 검증)
//   3. image_url이 있으면 Storage 'posts' 버킷에서 파일 삭제
//   4. posts 테이블에서 행 삭제
//
// Request  : POST { post_id: string }
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

  const { post_id: postId } = await req.json();
  if (!postId) return errorResponse('post_id is required', 400);

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  try {
    // 2. 게시글 조회 + 소유자 검증
    const { data: post, error: fetchError } = await adminClient
      .from('posts')
      .select('image_url, user_id')
      .eq('id', postId)
      .single();

    if (fetchError || !post) return errorResponse('Post not found', 404);
    if (post.user_id !== uid) return errorResponse('Forbidden', 403);

    // 3. Storage 이미지 삭제
    if (post.image_url) {
      const marker = '/object/public/posts/';
      const idx = post.image_url.indexOf(marker);
      if (idx !== -1) {
        const path = post.image_url.substring(idx + marker.length);
        await adminClient.storage.from('posts').remove([path]);
      }
    }

    // 4. DB 행 삭제
    const { error: deleteError } = await adminClient
      .from('posts')
      .delete()
      .eq('id', postId);

    if (deleteError) throw new Error(`DB delete failed: ${deleteError.message}`);

    return jsonResponse({ success: true });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error('[delete-post] Error:', message);
    return errorResponse(`Delete failed: ${message}`, 500);
  }
});
