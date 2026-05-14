-- supabase/migrations/20260513000000_appointment_schema.sql

-- ── Enum ──────────────────────────────────────────────────────────────────

do $$ begin
  create type invite_status as enum ('pending', 'accepted', 'rejected', 'cancelled');
exception when duplicate_object then null;
end $$;

-- ── appointments ──────────────────────────────────────────────────────────

create table public.appointments (
  id               uuid default gen_random_uuid() primary key,
  event_id         uuid references public.events(id) on delete cascade not null,
  creator_id       uuid references public.profiles(id) on delete cascade not null,
  suggested_place  text,
  created_at       timestamptz default now() not null
);

create index appointments_creator_id_idx on public.appointments (creator_id);
create index appointments_event_id_idx   on public.appointments (event_id);

alter table public.appointments enable row level security;

create policy "약속 생성: 본인만"
  on public.appointments for insert with check (auth.uid() = creator_id);

-- creator만 삭제 가능 (취소 시 cascade로 invites도 삭제)
create policy "약속 삭제: creator만"
  on public.appointments for delete using (auth.uid() = creator_id);

-- ※ "약속 조회: creator 또는 초대받은 사람" 정책은
--    appointment_invites 테이블 생성 이후에 추가됨 (아래 참고)

-- ── appointment_invites ───────────────────────────────────────────────────

create table public.appointment_invites (
  id               uuid default gen_random_uuid() primary key,
  appointment_id   uuid references public.appointments(id) on delete cascade not null,
  invitee_id       uuid references public.profiles(id) on delete cascade not null,
  status           invite_status not null default 'pending',
  updated_at       timestamptz default now() not null,
  unique (appointment_id, invitee_id)
);

create index appointment_invites_invitee_id_idx       on public.appointment_invites (invitee_id);
create index appointment_invites_appointment_id_idx   on public.appointment_invites (appointment_id);

alter table public.appointment_invites enable row level security;

-- appointment_invites 생성 후 appointments SELECT 정책 추가
-- (정책 내 subquery가 appointment_invites를 참조하므로 테이블 먼저 생성 필요)
create policy "약속 조회: creator 또는 초대받은 사람"
  on public.appointments for select using (
    auth.uid() = creator_id
    or exists (
      select 1 from public.appointment_invites
      where appointment_id = appointments.id
        and invitee_id = auth.uid()
    )
  );

-- creator 또는 당사자 invitee 조회 가능
create policy "초대 조회: creator 또는 invitee"
  on public.appointment_invites for select using (
    invitee_id = auth.uid()
    or exists (
      select 1 from public.appointments
      where id = appointment_invites.appointment_id
        and creator_id = auth.uid()
    )
  );

-- creator만 invite 생성 가능
create policy "초대 생성: creator만"
  on public.appointment_invites for insert with check (
    exists (
      select 1 from public.appointments
      where id = appointment_invites.appointment_id
        and creator_id = auth.uid()
    )
  );

-- invitee 본인이 수락/거절 가능, creator가 취소 가능
-- WITH CHECK: 상태 전이 권한을 DB 레벨에서 강제
--   invitee → accepted / rejected 만 허용
--   creator → cancelled 만 허용
create policy "초대 상태 변경: invitee(수락/거절) 또는 creator(취소)"
  on public.appointment_invites for update
  using (
    invitee_id = auth.uid()
    or exists (
      select 1 from public.appointments
      where id = appointment_invites.appointment_id
        and creator_id = auth.uid()
    )
  )
  with check (
    (invitee_id = auth.uid() and status in ('accepted', 'rejected'))
    or exists (
      select 1 from public.appointments
      where id = appointment_invites.appointment_id
        and creator_id = auth.uid()
    )
  );

-- ── events.appointment_id FK 확정 ─────────────────────────────────────────
-- calendar_schema.sql에서 uuid(nullable)로 이미 존재. FK 제약만 추가.

alter table public.events
  add constraint events_appointment_id_fkey
  foreign key (appointment_id) references public.appointments(id)
  on delete set null;

-- ── Trigger: 수락 시 invitee 캘린더에 이벤트 복제 ────────────────────────

create or replace function sync_event_on_invite_accept()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- 상태가 accepted로 바뀐 경우만 실행
  if NEW.status = 'accepted' and OLD.status <> 'accepted' then
    -- 중복 복제 방지: invitee의 복제 이벤트가 이미 존재하면 skip
    if not exists (
      select 1 from public.events
      where appointment_id = NEW.appointment_id
        and user_id = NEW.invitee_id
    ) then
      insert into public.events (
        user_id, title, location, location_lat, location_lng,
        start_at, end_at, color, is_dday, memo, notify_before_min,
        status, appointment_id, visibility
      )
      select
        NEW.invitee_id,
        e.title,
        e.location,
        e.location_lat,
        e.location_lng,
        e.start_at,
        e.end_at,
        e.color,
        e.is_dday,
        e.memo,
        e.notify_before_min,
        'pending',
        a.id,
        'private'
      from public.appointments a
      join public.events e on e.id = a.event_id
      where a.id = NEW.appointment_id;
    end if;
  end if;
  return NEW;
end;
$$;

create trigger trg_invite_accepted
  after update on public.appointment_invites
  for each row
  execute function sync_event_on_invite_accept();

-- ── Trigger: 취소 시 invitee 복제 이벤트 삭제 ────────────────────────────

create or replace function cleanup_event_on_invite_cancel()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if NEW.status = 'cancelled' and OLD.status <> 'cancelled' then
    -- invitee가 수락해서 복제된 이벤트만 삭제 (appointment_id 매칭)
    delete from public.events
    where appointment_id = NEW.appointment_id
      and user_id = NEW.invitee_id;
  end if;
  return NEW;
end;
$$;

create trigger trg_invite_cancelled
  after update on public.appointment_invites
  for each row
  execute function cleanup_event_on_invite_cancel();

-- ── updated_at 자동 갱신 ──────────────────────────────────────────────────

create or replace function touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  NEW.updated_at = now();
  return NEW;
end;
$$;

create trigger trg_appointment_invites_updated_at
  before update on public.appointment_invites
  for each row
  execute function touch_updated_at();

-- ── RPC: 약속 생성 원자 트랜잭션 ──────────────────────────────────────────
-- appointments INSERT + appointment_invites batch INSERT + events.appointment_id UPDATE
-- 을 단일 트랜잭션으로 처리하여 중간 실패 시 고아 레코드 방지

create or replace function create_appointment_with_invites(
  p_event_id       uuid,
  p_invitee_ids    uuid[],
  p_suggested_place text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_appointment_id uuid;
begin
  -- p_event_id가 호출자 소유인지 검증
  if not exists (
    select 1 from public.events
    where id = p_event_id and user_id = auth.uid()
  ) then
    raise exception 'event not found or not owned by caller';
  end if;

  insert into public.appointments (event_id, creator_id, suggested_place)
  values (p_event_id, auth.uid(), p_suggested_place)
  returning id into v_appointment_id;

  insert into public.appointment_invites (appointment_id, invitee_id)
  select v_appointment_id, unnest(p_invitee_ids);

  update public.events
  set appointment_id = v_appointment_id
  where id = p_event_id
    and user_id = auth.uid();

  return v_appointment_id;
end;
$$;
