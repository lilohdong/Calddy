-- ============================================================
-- Calddy 친구 탭 더미 데이터 시드
-- 실행 위치: Supabase Dashboard → SQL Editor
-- 실행 전 준비: MY_USER_UUID 를 실제 로그인 유저 UUID로 교체
--   확인 방법: Supabase → Authentication → Users 탭에서 확인
-- ============================================================

-- ❗ 여기에 실제 로그인 유저 UUID를 입력하세요
-- 예: DO $$ DECLARE me uuid := 'a1b2c3d4-...';
DO $$
DECLARE
  me         uuid := 'MY_USER_UUID';   -- ← 여기 교체

  fan_id     uuid := 'aaaaaaaa-0001-4000-8000-000000000001';
  dev_id     uuid := 'aaaaaaaa-0002-4000-8000-000000000002';
  gamer_id   uuid := 'aaaaaaaa-0003-4000-8000-000000000003';
  artist_id  uuid := 'aaaaaaaa-0004-4000-8000-000000000004';
  star_id    uuid := 'aaaaaaaa-0005-4000-8000-000000000005';
BEGIN

-- ============================================================
-- STEP 1: auth.users 에 더미 계정 5개 삽입
--         (Supabase SQL Editor는 postgres 권한이므로 직접 INSERT 가능)
-- ============================================================
INSERT INTO auth.users (
  id, email, encrypted_password, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data,
  aud, role
)
VALUES
  (fan_id,    'calddy_fan@dummy.calddy',    '', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
  (dev_id,    'calddy_dev@dummy.calddy',    '', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
  (gamer_id,  'calddy_gamer@dummy.calddy',  '', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
  (artist_id, 'calddy_artist@dummy.calddy', '', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
  (star_id,   'calddy_star@dummy.calddy',   '', now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 2: profiles 테이블에 더미 유저 프로필 5개 삽입
-- ============================================================
INSERT INTO profiles (id, nickname, avatar_url, bio, push_enabled, is_onboarded)
VALUES
  (fan_id,    'Calddy_Fan',    null, '캘린더 덕후예요 📅',       false, true),
  (dev_id,    'Calddy_Dev',    null, '개발자 지망생 💻',         false, true),
  (gamer_id,  'Calddy_Gamer',  null, '게임이 인생 🎮',           false, true),
  (artist_id, 'Calddy_Artist', null, '그림 그리는 걸 좋아해요 🎨', false, true),
  (star_id,   'Calddy_Star',   null, '반짝반짝 ⭐',              false, true)
ON CONFLICT (id) DO UPDATE
  SET nickname = EXCLUDED.nickname,
      bio      = EXCLUDED.bio;

-- ============================================================
-- STEP 3: friends 테이블에 수락된 친구 관계 삽입 (양방향)
--         Fan, Dev, Gamer, Artist → 수락된 친구
--         Star → 아직 요청 중 (friends에는 없음)
-- ============================================================
INSERT INTO friends (user_id, friend_id, created_at)
VALUES
  -- Fan
  (me,        fan_id,    now() - interval '20 days'),
  (fan_id,    me,        now() - interval '20 days'),
  -- Dev
  (me,        dev_id,    now() - interval '15 days'),
  (dev_id,    me,        now() - interval '15 days'),
  -- Gamer
  (me,        gamer_id,  now() - interval '10 days'),
  (gamer_id,  me,        now() - interval '10 days'),
  -- Artist
  (me,        artist_id, now() - interval '5 days'),
  (artist_id, me,        now() - interval '5 days')
ON CONFLICT DO NOTHING;

-- ============================================================
-- STEP 4: friend_requests 테이블에 pending 요청 1개 삽입
--         Star → Me 방향 (받은 요청 → UI에 "새로운 친구 요청" 표시)
-- ============================================================
INSERT INTO friend_requests (requester_id, addressee_id, status, created_at)
VALUES
  (star_id, me, 'pending', now() - interval '1 hour')
ON CONFLICT DO NOTHING;

-- ============================================================
-- STEP 5: events 테이블에 각 친구의 공개 일정 삽입
--         visibility = 'public' → 내가 볼 수 있음
--         이번 달(2026-06) 기준으로 작성
-- ============================================================

-- Calddy_Fan 의 일정
INSERT INTO events (id, user_id, title, start_at, end_at, color, visibility, status)
VALUES
  (gen_random_uuid(), fan_id, '여행 준비',   '2026-06-06 09:00:00+09', '2026-06-06 11:00:00+09', '#7C6AFA', 'public', 'pending'),
  (gen_random_uuid(), fan_id, '스터디',      '2026-06-09 14:00:00+09', '2026-06-09 16:00:00+09', '#5BB5E8', 'public', 'pending'),
  (gen_random_uuid(), fan_id, '프로젝트 마감','2026-06-28 00:00:00+09', '2026-06-28 23:59:00+09', '#F07DB3', 'public', 'pending')
ON CONFLICT DO NOTHING;

-- Calddy_Dev 의 일정
INSERT INTO events (id, user_id, title, start_at, end_at, color, visibility, status)
VALUES
  (gen_random_uuid(), dev_id, '회의',  '2026-06-07 13:00:00+09', '2026-06-07 14:00:00+09', '#6EC6B8', 'public', 'pending'),
  (gen_random_uuid(), dev_id, '운동',  '2026-06-13 07:00:00+09', '2026-06-13 08:00:00+09', '#6EC6B8', 'public', 'pending'),
  (gen_random_uuid(), dev_id, '회식',  '2026-06-10 19:00:00+09', '2026-06-10 22:00:00+09', '#F5A623', 'public', 'pending')
ON CONFLICT DO NOTHING;

-- Calddy_Gamer 의 일정
INSERT INTO events (id, user_id, title, start_at, end_at, color, visibility, status)
VALUES
  (gen_random_uuid(), gamer_id, '카페 약속', '2026-06-17 15:00:00+09', '2026-06-17 17:00:00+09', '#F5A623', 'public', 'pending'),
  (gen_random_uuid(), gamer_id, '스터디',    '2026-06-09 14:00:00+09', '2026-06-09 16:00:00+09', '#5BB5E8', 'public', 'pending')
ON CONFLICT DO NOTHING;

-- Calddy_Artist 의 일정
INSERT INTO events (id, user_id, title, start_at, end_at, color, visibility, status)
VALUES
  (gen_random_uuid(), artist_id, '전시회',     '2026-06-21 11:00:00+09', '2026-06-21 18:00:00+09', '#F07DB3', 'public', 'pending'),
  (gen_random_uuid(), artist_id, '생일 파티',  '2026-06-19 18:00:00+09', '2026-06-19 22:00:00+09', '#F07DB3', 'public', 'pending'),
  (gen_random_uuid(), artist_id, '데이트',     '2026-06-24 14:00:00+09', '2026-06-24 18:00:00+09', '#A3D977', 'public', 'pending')
ON CONFLICT DO NOTHING;

RAISE NOTICE '✅ 친구 더미 데이터 삽입 완료!';
RAISE NOTICE '   친구 4명: Calddy_Fan, Calddy_Dev, Calddy_Gamer, Calddy_Artist';
RAISE NOTICE '   받은 친구 요청 1건: Calddy_Star';
RAISE NOTICE '   공개 일정: Fan 3건 / Dev 3건 / Gamer 2건 / Artist 3건';

END $$;
