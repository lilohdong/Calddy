-- ============================================================
-- reports 테이블
--
-- 게시글 / 댓글 / 유저 신고를 단일 테이블에서 처리 (polymorphic).
-- UNIQUE(reporter_id, target_type, target_id): 동일 대상 중복 신고 방지.
-- status 관리(pending → reviewed)는 관리자 service_role로만 처리.
-- ============================================================


-- ============================================================
-- 1. Enum
-- ============================================================

do $$ begin
  create type report_target_type as enum ('post', 'comment', 'user');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type report_status as enum ('pending', 'reviewed');
exception when duplicate_object then null;
end $$;


-- ============================================================
-- 2. reports 테이블
-- ============================================================

create table if not exists public.reports (
  id           uuid               default gen_random_uuid() primary key,
  reporter_id  uuid               references public.profiles(id) on delete cascade not null,
  target_type  report_target_type not null,
  target_id    uuid               not null,
  reason       text               not null,
  status       report_status      not null default 'pending',
  created_at   timestamptz        default now() not null,

  -- 동일 대상 중복 신고 방지
  constraint reports_unique unique (reporter_id, target_type, target_id)
);


-- ============================================================
-- 3. 인덱스
-- ============================================================

-- 관리자 미처리 신고 목록 조회
create index if not exists reports_status_created_at_idx
  on public.reports (status, created_at)
  where status = 'pending';

-- 특정 대상의 신고 내역 조회
create index if not exists reports_target_idx
  on public.reports (target_type, target_id);


-- ============================================================
-- 4. RLS
-- ============================================================

alter table public.reports enable row level security;

-- INSERT: 인증 유저, 본인이 reporter인 경우만
create policy "reports: 본인으로 신고 접수"
  on public.reports for insert to authenticated
  with check (reporter_id = auth.uid());

-- SELECT: 본인이 접수한 신고 내역만 조회 가능
create policy "reports: 본인 신고 내역 조회"
  on public.reports for select to authenticated
  using (reporter_id = auth.uid());

-- UPDATE / DELETE 정책 없음
-- status 변경 및 삭제는 관리자 service_role로만 처리
