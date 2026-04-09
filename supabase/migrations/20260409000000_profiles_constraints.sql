-- ============================================================
-- Fix 1: profiles.email → nullable
--   - 구글 계정의 이메일 비공개 시 '@noemail.calddy' 가짜 이메일이
--     unique not null 컬럼에 저장되는 문제 해결.
--   - auth.users.email 자체가 nullable이므로 profiles.email도 동일하게 처리.
--   - UNIQUE 제약은 유지 (PostgreSQL은 NULL = NULL을 성립시키지 않으므로
--     NULL 값이 여러 행에 있어도 unique 위반이 아님).
-- ============================================================
alter table public.profiles
  alter column email drop not null;

-- handle_new_user 트리거에서 가짜 이메일 대신 NULL 저장으로 변경
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, nickname, avatar_url, is_onboarded)
  values (
    new.id,
    new.email,  -- NULL 허용: 이메일 비공개 구글 계정은 NULL로 저장
    'u_' || substr(replace(new.id::text, '-', ''), 1, 18),
    new.raw_user_meta_data->>'avatar_url',
    false
  );
  return new;
end;
$$ language plpgsql security definer;

-- ============================================================
-- Note: profiles INSERT RLS 정책 설계 의도
--   - handle_new_user 트리거가 security definer로 실행되므로 RLS를 우회하여 INSERT.
--   - 별도 INSERT RLS 정책이 없으면 일반 클라이언트에서 profiles INSERT 불가 (기본 거부).
--   - 이는 의도된 설계: 프로필 생성은 반드시 트리거를 통해서만 이루어져야 한다.
-- ============================================================

-- ============================================================
-- Fix 2: profiles.nickname 형식 check constraint
--   - 클라이언트 검증(Presentation 레이어)을 우회하는 임의 문자 저장 방지.
--   - 허용: 한글(가-힣), 영문 대소문자, 숫자, 언더스코어(_), 하이픈(-), 2~20자.
--   - NOT VALID: 기존 행(트리거 생성 임시 닉네임 등)은 검사하지 않음.
--                신규 INSERT / UPDATE되는 행부터 제약이 적용됨.
-- ============================================================
alter table public.profiles
  add constraint profiles_nickname_format
  check (nickname ~ '^[가-힣a-zA-Z0-9_\-]{2,20}$') not valid;
