-- supabase/migrations/20260507000000_calendar_schema.sql

-- 기존 schedules 테이블 제거 (실 데이터 없음)
drop table if exists public.schedules cascade;

-- Enum 타입 (이미 존재할 경우 오류 방지)
do $$ begin
  create type event_status as enum ('pending', 'done');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type event_visibility as enum ('public', 'private');
exception when duplicate_object then null;
end $$;

-- events 테이블
create table public.events (
  id                uuid default gen_random_uuid() primary key,
  user_id           uuid references public.profiles(id) on delete cascade not null,
  title             text not null,
  location          text,
  location_lat      double precision,
  location_lng      double precision,
  start_at          timestamptz not null,
  end_at            timestamptz not null,
  color             text not null default '#4A90D9',
  is_dday           boolean not null default false,
  memo              text,
  notify_before_min integer,
  status            event_status not null default 'pending',
  appointment_id    uuid,  -- P2에서 appointments(id) FK 추가 예정
  visibility        event_visibility not null default 'public',
  created_at        timestamptz default now() not null,
  constraint end_after_start check (end_at > start_at)
);

-- 월별 조회 성능 인덱스
create index events_user_id_start_at_idx on public.events (user_id, start_at);

-- RLS 활성화
alter table public.events enable row level security;

-- SELECT: 본인 전체 + 친구의 public 일정
create policy "본인 또는 친구 public 일정 조회"
  on public.events for select using (
    auth.uid() = user_id
    or (
      visibility = 'public'
      and exists (
        select 1 from public.friendships
        where (user_id_1 = auth.uid() and user_id_2 = events.user_id and status = 'accepted')
           or (user_id_1 = events.user_id and user_id_2 = auth.uid() and status = 'accepted')
      )
    )
  );

create policy "본인 일정만 생성" on public.events
  for insert with check (auth.uid() = user_id);

create policy "본인 일정만 수정" on public.events
  for update using (auth.uid() = user_id);

create policy "본인 일정만 삭제" on public.events
  for delete using (auth.uid() = user_id);
