-- ============================================================
-- profiles 테이블 확장
--
-- 추가 컬럼:
--   - birth_date         : 생년월일
--   - push_enabled       : FCM 수신 여부
--   - fcm_token          : Firebase 디바이스 토큰
--   - home_lat/lng       : 중간지점 계산용 좌표 (5. Map)
--   - nickname_changed_at: 닉네임 30일 1회 변경 제한
--   - terms_agreed_at    : 이용약관 동의 시각
--   - terms_version      : 동의한 약관 버전
--   - deleted_at         : 탈퇴 soft delete 마킹
-- ============================================================

alter table public.profiles
  add column if not exists birth_date           date,
  add column if not exists push_enabled         boolean          not null default true,
  add column if not exists fcm_token            text,
  add column if not exists home_lat             double precision,
  add column if not exists home_lng             double precision,
  add column if not exists nickname_changed_at  timestamptz,
  add column if not exists terms_agreed_at      timestamptz,
  add column if not exists terms_version        text,
  add column if not exists deleted_at           timestamptz;
