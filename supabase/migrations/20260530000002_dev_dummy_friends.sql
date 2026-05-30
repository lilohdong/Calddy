-- ============================================================
-- [DEV ONLY] 더미 데이터: 테스트 유저 + 친구 3명 + 각 10개 공개 일정
--
-- 테스트 계정 (비밀번호: calddy1234)
--   메인 유저:  test@calddy.dev     (테스트계정)
--   친구 1:     friend1@calddy.dev  (김민준)
--   친구 2:     friend2@calddy.dev  (이서연)
--   친구 3:     friend3@calddy.dev  (박지훈)
-- ============================================================

DO $$
DECLARE
  v_main uuid := 'a1000000-0000-0000-0000-000000000001'::uuid;
  v_f1   uuid := 'b1000000-0000-0000-0000-000000000001'::uuid;
  v_f2   uuid := 'c1000000-0000-0000-0000-000000000001'::uuid;
  v_f3   uuid := 'd1000000-0000-0000-0000-000000000001'::uuid;
BEGIN

  -- ── auth.users ───────────────────────────────────────────
  INSERT INTO auth.users (
    instance_id, id, aud, role, email,
    encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, created_at, updated_at
  ) VALUES
    ('00000000-0000-0000-0000-000000000000', v_main, 'authenticated', 'authenticated',
     'test@calddy.dev',    extensions.crypt('calddy1234', extensions.gen_salt('bf')), now(),
     '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, false, now(), now()),
    ('00000000-0000-0000-0000-000000000000', v_f1,   'authenticated', 'authenticated',
     'friend1@calddy.dev', extensions.crypt('calddy1234', extensions.gen_salt('bf')), now(),
     '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, false, now(), now()),
    ('00000000-0000-0000-0000-000000000000', v_f2,   'authenticated', 'authenticated',
     'friend2@calddy.dev', extensions.crypt('calddy1234', extensions.gen_salt('bf')), now(),
     '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, false, now(), now()),
    ('00000000-0000-0000-0000-000000000000', v_f3,   'authenticated', 'authenticated',
     'friend3@calddy.dev', extensions.crypt('calddy1234', extensions.gen_salt('bf')), now(),
     '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, false, now(), now())
  ON CONFLICT (id) DO NOTHING;

  -- 트리거가 자동 생성한 u_xxx 닉네임을 읽기 쉬운 이름으로 교체
  UPDATE public.profiles SET nickname = '테스트계정' WHERE id = v_main AND nickname LIKE 'u_%';
  UPDATE public.profiles SET nickname = '김민준'     WHERE id = v_f1   AND nickname LIKE 'u_%';
  UPDATE public.profiles SET nickname = '이서연'     WHERE id = v_f2   AND nickname LIKE 'u_%';
  UPDATE public.profiles SET nickname = '박지훈'     WHERE id = v_f3   AND nickname LIKE 'u_%';

  -- ── friends (양방향) ─────────────────────────────────────
  INSERT INTO public.friends (user_id, friend_id) VALUES
    (v_main, v_f1), (v_f1, v_main),
    (v_main, v_f2), (v_f2, v_main),
    (v_main, v_f3), (v_f3, v_main)
  ON CONFLICT DO NOTHING;

  -- ── 친구 1 (김민준) 공개 일정 10개 ──────────────────────
  INSERT INTO public.events (user_id, title, start_at, end_at, color, visibility, status) VALUES
    (v_f1, '헬스장',     '2026-05-01 07:00:00+09', '2026-05-01 08:00:00+09', '#FF5733', 'public', 'done'),
    (v_f1, '점심 약속',  '2026-05-03 12:00:00+09', '2026-05-03 13:00:00+09', '#4A90D9', 'public', 'done'),
    (v_f1, '영화 관람',  '2026-05-05 18:00:00+09', '2026-05-05 20:00:00+09', '#9B59B6', 'public', 'done'),
    (v_f1, '독서모임',   '2026-05-08 19:00:00+09', '2026-05-08 21:00:00+09', '#27AE60', 'public', 'done'),
    (v_f1, '카페 공부',  '2026-05-10 14:00:00+09', '2026-05-10 17:00:00+09', '#F39C12', 'public', 'done'),
    (v_f1, '등산',       '2026-05-12 09:00:00+09', '2026-05-12 13:00:00+09', '#27AE60', 'public', 'done'),
    (v_f1, '생일 파티',  '2026-05-15 18:00:00+09', '2026-05-15 22:00:00+09', '#E74C3C', 'public', 'done'),
    (v_f1, '헬스장',     '2026-05-18 07:00:00+09', '2026-05-18 08:00:00+09', '#FF5733', 'public', 'done'),
    (v_f1, '카페 미팅',  '2026-05-22 15:00:00+09', '2026-05-22 16:00:00+09', '#4A90D9', 'public', 'done'),
    (v_f1, '저녁 식사',  '2026-05-27 19:00:00+09', '2026-05-27 21:00:00+09', '#E67E22', 'public', 'done');

  -- ── 친구 2 (이서연) 공개 일정 10개 ──────────────────────
  INSERT INTO public.events (user_id, title, start_at, end_at, color, visibility, status) VALUES
    (v_f2, '요가 클래스', '2026-05-02 07:00:00+09', '2026-05-02 08:00:00+09', '#FF8FA3', 'public', 'done'),
    (v_f2, '팀 회의',     '2026-05-04 10:00:00+09', '2026-05-04 11:00:00+09', '#4A90D9', 'public', 'done'),
    (v_f2, '쇼핑',        '2026-05-06 14:00:00+09', '2026-05-06 17:00:00+09', '#E91E63', 'public', 'done'),
    (v_f2, '피아노 레슨', '2026-05-09 16:00:00+09', '2026-05-09 17:00:00+09', '#9C27B0', 'public', 'done'),
    (v_f2, '저녁 모임',   '2026-05-11 18:00:00+09', '2026-05-11 21:00:00+09', '#FF5733', 'public', 'done'),
    (v_f2, '미용실',      '2026-05-14 13:00:00+09', '2026-05-14 14:30:00+09', '#FF8FA3', 'public', 'done'),
    (v_f2, '영어 수업',   '2026-05-16 19:00:00+09', '2026-05-16 20:30:00+09', '#4A90D9', 'public', 'done'),
    (v_f2, '가족 모임',   '2026-05-20 12:00:00+09', '2026-05-20 15:00:00+09', '#27AE60', 'public', 'done'),
    (v_f2, '카페',        '2026-05-24 11:00:00+09', '2026-05-24 13:00:00+09', '#F39C12', 'public', 'done'),
    (v_f2, '헬스장',      '2026-05-28 07:00:00+09', '2026-05-28 08:00:00+09', '#FF8FA3', 'public', 'done');

  -- ── 친구 3 (박지훈) 공개 일정 10개 ──────────────────────
  INSERT INTO public.events (user_id, title, start_at, end_at, color, visibility, status) VALUES
    (v_f3, '풋살',        '2026-05-01 16:00:00+09', '2026-05-01 18:00:00+09', '#2ECC71', 'public', 'done'),
    (v_f3, '스터디',      '2026-05-03 14:00:00+09', '2026-05-03 17:00:00+09', '#3498DB', 'public', 'done'),
    (v_f3, '게임',        '2026-05-07 20:00:00+09', '2026-05-07 22:00:00+09', '#9B59B6', 'public', 'done'),
    (v_f3, '드라이브',    '2026-05-09 10:00:00+09', '2026-05-09 14:00:00+09', '#1ABC9C', 'public', 'done'),
    (v_f3, '클라이밍',    '2026-05-12 17:00:00+09', '2026-05-12 19:00:00+09', '#E74C3C', 'public', 'done'),
    (v_f3, '영화',        '2026-05-16 19:00:00+09', '2026-05-16 21:00:00+09', '#9B59B6', 'public', 'done'),
    (v_f3, '독서',        '2026-05-19 21:00:00+09', '2026-05-19 22:00:00+09', '#3498DB', 'public', 'done'),
    (v_f3, '풋살',        '2026-05-22 16:00:00+09', '2026-05-22 18:00:00+09', '#2ECC71', 'public', 'done'),
    (v_f3, '카페 공부',   '2026-05-25 13:00:00+09', '2026-05-25 16:00:00+09', '#F39C12', 'public', 'done'),
    (v_f3, '보드게임',    '2026-05-28 18:00:00+09', '2026-05-28 21:00:00+09', '#E67E22', 'public', 'done');

END $$;
