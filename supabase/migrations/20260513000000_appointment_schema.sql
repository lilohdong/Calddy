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

-- creator 본인만 조회
create policy "약속 조회: creator 또는 초대받은 사람"
  on public.appointments for select using (
    auth.uid() = creator_id
    or exists (
      select 1 from public.appointment_invites
      where appointment_id = appointments.id
        and invitee_id = auth.uid()
    )
  );

create policy "약속 생성: 본인만"
  on public.appointments for insert with check (auth.uid() = creator_id);

-- creator만 삭제 가능 (취소 시 cascade로 invites도 삭제)
create policy "약속 삭제: creator만"
  on public.appointments for delete using (auth.uid() = creator_id);

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
create policy "초대 상태 변경: invitee(수락/거절) 또는 creator(취소)"
  on public.appointment_invites for update using (
    invitee_id = auth.uid()
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
