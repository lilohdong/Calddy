-- ============================================================
-- Storage 버킷 생성 + RLS 정책
-- drawings / avatars / posts
-- ============================================================

-- ── 버킷 생성 ─────────────────────────────────────────────────

-- drawings: 꾸미기 썸네일 (5 MB 제한)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('drawings', 'drawings', true, 5242880, ARRAY['image/png','image/jpeg','image/webp'])
ON CONFLICT (id) DO NOTHING;

-- avatars: 프로필 사진 (2 MB 제한)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('avatars', 'avatars', true, 2097152, ARRAY['image/png','image/jpeg','image/webp'])
ON CONFLICT (id) DO NOTHING;

-- posts: 피드 게시글 이미지 (10 MB 제한)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('posts', 'posts', true, 10485760, ARRAY['image/png','image/jpeg','image/webp'])
ON CONFLICT (id) DO NOTHING;


-- ── drawings RLS ──────────────────────────────────────────────
-- 업로드 경로 패턴: drawing_{userId}_{date}.png (평탄 구조)

CREATE POLICY "drawings storage: 공개 조회"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'drawings');

CREATE POLICY "drawings storage: 본인만 업로드"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'drawings'
    AND name LIKE 'drawing_' || auth.uid()::text || '_%'
  );

CREATE POLICY "drawings storage: 본인만 수정(upsert)"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'drawings'
    AND name LIKE 'drawing_' || auth.uid()::text || '_%'
  );

CREATE POLICY "drawings storage: 본인만 삭제"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'drawings'
    AND name LIKE 'drawing_' || auth.uid()::text || '_%'
  );


-- ── avatars RLS ───────────────────────────────────────────────
-- 업로드 경로 패턴: {userId}/avatar.{ext} (폴더 구조)

CREATE POLICY "avatars storage: 공개 조회"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'avatars');

CREATE POLICY "avatars storage: 본인만 업로드"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "avatars storage: 본인만 수정(upsert)"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "avatars storage: 본인만 삭제"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );


-- ── posts RLS ─────────────────────────────────────────────────
-- 업로드 경로 패턴: {userId}/{filename} (폴더 구조)

CREATE POLICY "posts storage: 공개 조회"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'posts');

CREATE POLICY "posts storage: 본인만 업로드"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'posts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "posts storage: 본인만 수정(upsert)"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'posts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "posts storage: 본인만 삭제"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'posts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
