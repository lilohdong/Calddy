-- ============================================================
-- drawings 테이블 + holidays 테이블
--
-- drawings:
--   - 날짜별 손그림을 stroke 벡터 데이터로 저장 (perfect_freehand 연동)
--   - UNIQUE(user_id, draw_date): 하루 1개, upsert 방식 저장
--   - thumbnail_url: 추후 PNG 썸네일 확장용 (현재 nullable)
--
-- holidays:
--   - 대한민국 공휴일 정적 시드 (2025~2027)
--   - 클라이언트 직접 수정 불가, Flutter에서 shared_preferences 캐싱 권장
-- ============================================================


-- ============================================================
-- 1. drawings 테이블
-- ============================================================

create table if not exists public.drawings (
  id            uuid        default gen_random_uuid() primary key,
  user_id       uuid        references public.profiles(id) on delete cascade not null,
  draw_date     date        not null,
  -- perfect_freehand StrokePoint 배열: [{color, width, points: [[x,y],...]}]
  strokes       jsonb       not null default '[]',
  thumbnail_url text,
  updated_at    timestamptz default now() not null,

  unique(user_id, draw_date)
);

alter table public.drawings enable row level security;

create policy "drawings: 본인만 조회"
  on public.drawings for select to authenticated
  using (user_id = auth.uid());

create policy "drawings: 본인만 생성"
  on public.drawings for insert to authenticated
  with check (user_id = auth.uid());

create policy "drawings: 본인만 수정"
  on public.drawings for update to authenticated
  using     (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "drawings: 본인만 삭제"
  on public.drawings for delete to authenticated
  using (user_id = auth.uid());


-- ============================================================
-- 2. holidays 테이블
-- ============================================================

create table if not exists public.holidays (
  date  date  primary key,
  name  text  not null
);

alter table public.holidays enable row level security;

-- 인증 유저 전체 읽기 허용, 쓰기 정책 없음 (service_role만 가능)
create policy "holidays: 인증 유저 전체 조회"
  on public.holidays for select to authenticated
  using (true);


-- ============================================================
-- 3. 대한민국 공휴일 시드 (2025~2027)
--
-- 고정 공휴일은 연도 관계없이 동일 날짜.
-- 음력 기반 공휴일(설날·추석·부처님오신날)은 연도별 직접 확인 필요.
-- ============================================================

insert into public.holidays (date, name) values

  -- ── 2025 ──────────────────────────────────────────────
  ('2025-01-01', '신정'),
  ('2025-01-28', '설날 연휴'),
  ('2025-01-29', '설날'),
  ('2025-01-30', '설날 연휴'),
  ('2025-03-01', '삼일절'),
  ('2025-05-05', '어린이날·부처님오신날'),  -- 두 공휴일 겹침
  ('2025-05-06', '어린이날 대체공휴일'),
  ('2025-06-06', '현충일'),
  ('2025-08-15', '광복절'),
  ('2025-10-03', '개천절'),
  ('2025-10-06', '추석 연휴'),
  ('2025-10-07', '추석'),
  ('2025-10-08', '추석 연휴'),
  ('2025-10-09', '한글날'),
  ('2025-12-25', '크리스마스'),

  -- ── 2026 ──────────────────────────────────────────────
  ('2026-01-01', '신정'),
  ('2026-02-16', '설날 연휴'),
  ('2026-02-17', '설날'),
  ('2026-02-18', '설날 연휴'),
  ('2026-03-01', '삼일절'),
  ('2026-03-02', '삼일절 대체공휴일'),    -- 3/1이 일요일
  ('2026-05-05', '어린이날'),
  ('2026-05-24', '부처님오신날'),
  ('2026-06-06', '현충일'),
  ('2026-08-15', '광복절'),
  ('2026-09-24', '추석 연휴'),
  ('2026-09-25', '추석'),
  ('2026-09-26', '추석 연휴'),
  ('2026-10-03', '개천절'),
  ('2026-10-09', '한글날'),
  ('2026-12-25', '크리스마스'),

  -- ── 2027 ──────────────────────────────────────────────
  ('2027-01-01', '신정'),
  ('2027-02-06', '설날 연휴'),
  ('2027-02-07', '설날'),
  ('2027-02-08', '설날 연휴'),
  ('2027-03-01', '삼일절'),
  ('2027-05-05', '어린이날'),
  ('2027-05-13', '부처님오신날'),
  ('2027-06-06', '현충일'),
  ('2027-08-15', '광복절'),
  ('2027-10-03', '개천절'),
  ('2027-10-04', '추석 연휴'),
  ('2027-10-05', '추석'),
  ('2027-10-06', '추석 연휴'),
  ('2027-10-09', '한글날'),
  ('2027-12-25', '크리스마스')

on conflict (date) do nothing;
