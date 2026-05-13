-- ============================================================
-- events 테이블 확장 — 반복(습관) / 구간 일정 지원
--
-- 설계 결정:
--   - 습관(habit)  = 반복 주기 설정이 있는 일정. 체크박스 없음.
--   - 구간(range)  = end_at이 하루 이상인 일정.
--   - 세 타입 모두 events 테이블 공유 (event_type 컬럼으로 구분).
--   - 반복 인스턴스는 Eager 생성 (Flutter에서 parent_event_id로 묶어 INSERT).
--
-- 수정 동작 (Flutter 레이어):
--   - "이 일정만"     : 해당 row UPDATE
--   - "이후 전체 수정": DELETE WHERE parent_event_id = X AND start_at >= target
--                      → 새 규칙으로 인스턴스 재생성
-- ============================================================


-- ============================================================
-- 1. Enum 타입
-- ============================================================

do $$ begin
  create type event_type as enum ('event', 'habit', 'range');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type recurrence_type as enum ('daily', 'weekly', 'monthly');
exception when duplicate_object then null;
end $$;


-- ============================================================
-- 2. events 컬럼 추가
-- ============================================================

alter table public.events
  add column if not exists event_type           event_type      not null default 'event',
  add column if not exists recurrence_type      recurrence_type,
  -- weekly  : [0,1,2,3,4,5,6] 중 선택 (0=일, 1=월 ... 6=토)
  -- monthly : [1..31] 중 선택 (매월 N일)
  add column if not exists recurrence_days      int[],
  -- null이면 생성 시점부터 1년치를 Flutter에서 Eager 생성
  add column if not exists recurrence_end_date  date,
  -- 반복 인스턴스가 가리키는 원본 이벤트 (첫 번째 인스턴스 = null)
  add column if not exists parent_event_id      uuid
    references public.events(id) on delete set null;


-- ============================================================
-- 3. 제약 조건
-- ============================================================

-- habit 타입이면 recurrence_type 필수
-- (ADD CONSTRAINT IF NOT EXISTS는 PG15 미지원 → DO 블록으로 처리)
do $$
begin
  if not exists (
    select 1 from information_schema.check_constraints
    where constraint_name = 'events_habit_requires_recurrence'
  ) then
    alter table public.events
      add constraint events_habit_requires_recurrence
      check (event_type <> 'habit' or recurrence_type is not null);
  end if;
end;
$$;


-- ============================================================
-- 4. 인덱스
-- ============================================================

-- 반복 인스턴스 조회 / "이후 전체 삭제" 쿼리 최적화
create index if not exists events_parent_event_id_idx
  on public.events (parent_event_id)
  where parent_event_id is not null;

-- 타입별 필터 (캘린더 뷰 렌더링 분기)
create index if not exists events_user_event_type_idx
  on public.events (user_id, event_type);
