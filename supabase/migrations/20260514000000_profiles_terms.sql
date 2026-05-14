-- ============================================================
-- profiles 테이블에 이용약관 동의 내역 컬럼 추가
--   - terms_agreed_at : 사용자가 이용약관에 동의한 일시 (UTC)
--   - terms_version   : 동의한 약관 버전 (e.g. '1.0', '1.1')
-- ============================================================
alter table public.profiles
  add column if not exists terms_agreed_at timestamptz,
  add column if not exists terms_version   text;
