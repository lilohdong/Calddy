-- ============================================================
-- Calddy — 전체 스키마 초기화 (squashed migration)
--
-- 이전 마이그레이션 파일 14개를 단일 파일로 통합.
-- supabase db reset 시 이 파일 하나만 적용됨.
--
-- 테이블 생성 순서 (FK 의존성):
--   profiles → events → friend_requests → friends
--   → appointments → appointment_invites
--   → drawings → holidays → posts → post_likes
--   → comments → notifications → reports
-- ============================================================


-- ============================================================
-- 1. Enum 타입
-- ============================================================

do $$ begin
  create type event_status as enum ('pending', 'done');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type event_visibility as enum ('public', 'private');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type event_type as enum ('event', 'habit', 'range');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type recurrence_type as enum ('daily', 'weekly', 'monthly');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type invite_status as enum ('pending', 'accepted', 'rejected', 'cancelled');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type post_visibility as enum ('public', 'private');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type notification_type as enum (
    'friend_request',
    'appointment_invite',
    'appointment_accepted',
    'appointment_rejected',
    'suggest_new_date',
    'post_liked',
    'post_commented'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type report_target_type as enum ('post', 'comment', 'user');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type report_status as enum ('pending', 'reviewed');
exception when duplicate_object then null;
end $$;


-- ============================================================
-- 2. profiles
-- ============================================================

create table public.profiles (
  id                   uuid        references auth.users on delete cascade not null primary key,
  email                text        unique,
  nickname             text        unique not null,
  avatar_url           text,
  bio                  text,
  birth_date           date,
  push_enabled         boolean     not null default true,
  fcm_token            text,
  home_lat             double precision,
  home_lng             double precision,
  nickname_changed_at  timestamptz,
  terms_agreed_at      timestamptz,
  terms_version        text,
  is_onboarded         boolean     not null default false,
  deleted_at           timestamptz,
  created_at           timestamptz not null default now()
);

alter table public.profiles
  add constraint profiles_nickname_format
  check (nickname ~ '^[가-힣a-zA-Z0-9_\-]{2,20}$') not valid;

alter table public.profiles enable row level security;

-- 인증 유저 전체 조회 (친구 검색용)
create policy "profiles: 인증 유저 전체 조회"
  on public.profiles for select to authenticated
  using (true);

create policy "profiles: 본인만 수정"
  on public.profiles for update to authenticated
  using     (id = auth.uid())
  with check (id = auth.uid());


-- ── 트리거: 신규 가입 시 profiles 자동 생성 ──────────────────

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles (id, email, nickname, avatar_url, is_onboarded)
  values (
    new.id,
    new.email,
    'u_' || substr(replace(new.id::text, '-', ''), 1, 18),
    new.raw_user_meta_data->>'avatar_url',
    false
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ============================================================
-- 3. events
-- ============================================================

create table public.events (
  id                  uuid             default gen_random_uuid() primary key,
  user_id             uuid             references public.profiles(id) on delete cascade not null,
  title               text             not null,
  location            text,
  location_lat        double precision,
  location_lng        double precision,
  start_at            timestamptz      not null,
  end_at              timestamptz      not null,
  color               text             not null default '#4A90D9',
  is_dday             boolean          not null default false,
  memo                text,
  notify_before_min   integer,
  status              event_status     not null default 'pending',
  appointment_id      uuid,            -- FK는 appointments 생성 후 추가
  visibility          event_visibility not null default 'public',
  event_type          event_type       not null default 'event',
  recurrence_type     recurrence_type,
  recurrence_days     int[],
  recurrence_end_date date,
  parent_event_id     uuid             references public.events(id) on delete set null,
  created_at          timestamptz      not null default now(),

  constraint end_after_start check (end_at > start_at),
  constraint events_habit_requires_recurrence
    check (event_type <> 'habit' or recurrence_type is not null)
);

create index events_user_id_start_at_idx on public.events (user_id, start_at);
create index events_parent_event_id_idx  on public.events (parent_event_id)
  where parent_event_id is not null;
create index events_user_event_type_idx  on public.events (user_id, event_type);

alter table public.events enable row level security;

create policy "events: 본인만 생성"
  on public.events for insert to authenticated
  with check (auth.uid() = user_id);

create policy "events: 본인만 수정"
  on public.events for update to authenticated
  using     (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "events: 본인만 삭제"
  on public.events for delete to authenticated
  using (auth.uid() = user_id);

-- SELECT는 friends 테이블 생성 후 추가 (아래 참고)


-- ============================================================
-- 4. friend_requests
-- ============================================================

create table public.friend_requests (
  id            uuid        default gen_random_uuid() primary key,
  requester_id  uuid        references public.profiles(id) on delete cascade not null,
  addressee_id  uuid        references public.profiles(id) on delete cascade not null,
  status        text        not null default 'pending'
                            check (status in ('pending', 'accepted', 'rejected')),
  created_at    timestamptz not null default now(),

  constraint friend_requests_unique  unique  (requester_id, addressee_id),
  constraint friend_requests_no_self check   (requester_id <> addressee_id)
);

create index friend_requests_addressee_status_idx on public.friend_requests (addressee_id, status);
create index friend_requests_requester_status_idx on public.friend_requests (requester_id, status);

alter table public.friend_requests enable row level security;

create policy "friend_requests: 당사자 조회"
  on public.friend_requests for select to authenticated
  using (requester_id = auth.uid() or addressee_id = auth.uid());

create policy "friend_requests: 본인이 요청자로 생성"
  on public.friend_requests for insert to authenticated
  with check (requester_id = auth.uid());

create policy "friend_requests: 수신자만 상태 변경"
  on public.friend_requests for update to authenticated
  using     (addressee_id = auth.uid())
  with check (addressee_id = auth.uid());

create policy "friend_requests: 요청자만 삭제"
  on public.friend_requests for delete to authenticated
  using (requester_id = auth.uid());


-- ============================================================
-- 5. friends
-- ============================================================

create table public.friends (
  user_id     uuid        references public.profiles(id) on delete cascade not null,
  friend_id   uuid        references public.profiles(id) on delete cascade not null,
  created_at  timestamptz not null default now(),

  primary key (user_id, friend_id),
  constraint friends_no_self check (user_id <> friend_id)
);

create index friends_user_id_idx on public.friends (user_id);

alter table public.friends enable row level security;

create policy "friends: 당사자 조회"
  on public.friends for select to authenticated
  using (user_id = auth.uid() or friend_id = auth.uid());

create policy "friends: 당사자 삭제"
  on public.friends for delete to authenticated
  using (user_id = auth.uid() or friend_id = auth.uid());

-- INSERT: 트리거(SECURITY DEFINER)만 허용 — 클라이언트 직접 삽입 차단


-- ── friends 생성 후: events SELECT 정책 추가 ─────────────────

create policy "events: 본인 또는 친구 public 일정 조회"
  on public.events for select to authenticated
  using (
    auth.uid() = user_id
    or (
      visibility = 'public'
      and exists (
        select 1 from public.friends
        where user_id   = auth.uid()
          and friend_id = events.user_id
      )
    )
  );


-- ── 트리거: 친구 요청 수락 → friends 양방향 INSERT ────────────

create or replace function public.handle_friend_request_accepted()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'accepted' and old.status = 'pending' then
    insert into public.friends (user_id, friend_id)
    values
      (new.addressee_id, new.requester_id),
      (new.requester_id, new.addressee_id)
    on conflict (user_id, friend_id) do nothing;
  end if;
  return new;
end;
$$;

create trigger trg_friend_request_accepted
  after update of status on public.friend_requests
  for each row
  execute function public.handle_friend_request_accepted();


-- ============================================================
-- 6. appointments
-- ============================================================

create table public.appointments (
  id               uuid default gen_random_uuid() primary key,
  event_id         uuid references public.events(id)   on delete cascade not null,
  creator_id       uuid references public.profiles(id) on delete cascade not null,
  suggested_place  text,
  created_at       timestamptz not null default now()
);

create index appointments_creator_id_idx on public.appointments (creator_id);
create index appointments_event_id_idx   on public.appointments (event_id);

alter table public.appointments enable row level security;

create policy "약속 생성: 본인만"
  on public.appointments for insert
  with check (auth.uid() = creator_id);

create policy "약속 삭제: creator만"
  on public.appointments for delete
  using (auth.uid() = creator_id);

-- SELECT는 appointment_invites 생성 후 추가 (아래 참고)


-- ============================================================
-- 7. appointment_invites
-- ============================================================

create table public.appointment_invites (
  id               uuid default gen_random_uuid() primary key,
  appointment_id   uuid references public.appointments(id) on delete cascade not null,
  invitee_id       uuid references public.profiles(id)     on delete cascade not null,
  status           invite_status not null default 'pending',
  updated_at       timestamptz   not null default now(),

  unique (appointment_id, invitee_id)
);

create index appointment_invites_invitee_id_idx     on public.appointment_invites (invitee_id);
create index appointment_invites_appointment_id_idx on public.appointment_invites (appointment_id);

alter table public.appointment_invites enable row level security;


-- ── appointment_invites 생성 후: appointments SELECT 정책 ────

create policy "약속 조회: creator 또는 초대받은 사람"
  on public.appointments for select using (
    auth.uid() = creator_id
    or exists (
      select 1 from public.appointment_invites
      where appointment_id = appointments.id
        and invitee_id = auth.uid()
    )
  );


-- ── appointment_invites RLS ───────────────────────────────────

create policy "초대 조회: creator 또는 invitee"
  on public.appointment_invites for select using (
    invitee_id = auth.uid()
    or exists (
      select 1 from public.appointments
      where id = appointment_invites.appointment_id
        and creator_id = auth.uid()
    )
  );

create policy "초대 생성: creator만"
  on public.appointment_invites for insert with check (
    exists (
      select 1 from public.appointments
      where id = appointment_invites.appointment_id
        and creator_id = auth.uid()
    )
  );

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


-- ── events.appointment_id FK 추가 ────────────────────────────

alter table public.events
  add constraint events_appointment_id_fkey
  foreign key (appointment_id) references public.appointments(id)
  on delete set null;


-- ── 트리거: 수락 시 invitee 캘린더에 이벤트 복제 ────────────

create or replace function sync_event_on_invite_accept()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'accepted' and old.status <> 'accepted' then
    if not exists (
      select 1 from public.events
      where appointment_id = new.appointment_id
        and user_id = new.invitee_id
    ) then
      insert into public.events (
        user_id, title, location, location_lat, location_lng,
        start_at, end_at, color, is_dday, memo, notify_before_min,
        status, appointment_id, visibility
      )
      select
        new.invitee_id, e.title, e.location, e.location_lat, e.location_lng,
        e.start_at, e.end_at, e.color, e.is_dday, e.memo, e.notify_before_min,
        'pending', a.id, 'private'
      from public.appointments a
      join public.events e on e.id = a.event_id
      where a.id = new.appointment_id;
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_invite_accepted
  after update on public.appointment_invites
  for each row
  execute function sync_event_on_invite_accept();


-- ── 트리거: 취소 시 invitee 복제 이벤트 삭제 ─────────────────

create or replace function cleanup_event_on_invite_cancel()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'cancelled' and old.status <> 'cancelled' then
    delete from public.events
    where appointment_id = new.appointment_id
      and user_id = new.invitee_id;
  end if;
  return new;
end;
$$;

create trigger trg_invite_cancelled
  after update on public.appointment_invites
  for each row
  execute function cleanup_event_on_invite_cancel();


-- ── 트리거: appointment_invites.updated_at 자동 갱신 ─────────

create or replace function touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_appointment_invites_updated_at
  before update on public.appointment_invites
  for each row
  execute function touch_updated_at();


-- ── RPC: 약속 생성 원자 트랜잭션 ─────────────────────────────

create or replace function create_appointment_with_invites(
  p_event_id        uuid,
  p_invitee_ids     uuid[],
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
  where id = p_event_id and user_id = auth.uid();

  return v_appointment_id;
end;
$$;


-- ============================================================
-- 8. drawings
-- ============================================================

create table public.drawings (
  id            uuid        default gen_random_uuid() primary key,
  user_id       uuid        references public.profiles(id) on delete cascade not null,
  draw_date     date        not null,
  strokes       jsonb       not null default '[]',
  thumbnail_url text,
  updated_at    timestamptz not null default now(),

  unique (user_id, draw_date)
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
-- 9. holidays (2025~2027 공휴일 시드 포함)
-- ============================================================

create table public.holidays (
  date  date primary key,
  name  text not null
);

alter table public.holidays enable row level security;

create policy "holidays: 인증 유저 전체 조회"
  on public.holidays for select to authenticated
  using (true);

insert into public.holidays (date, name) values
  ('2025-01-01', '신정'),
  ('2025-01-28', '설날 연휴'),
  ('2025-01-29', '설날'),
  ('2025-01-30', '설날 연휴'),
  ('2025-03-01', '삼일절'),
  ('2025-05-05', '어린이날·부처님오신날'),
  ('2025-05-06', '어린이날 대체공휴일'),
  ('2025-06-06', '현충일'),
  ('2025-08-15', '광복절'),
  ('2025-10-03', '개천절'),
  ('2025-10-06', '추석 연휴'),
  ('2025-10-07', '추석'),
  ('2025-10-08', '추석 연휴'),
  ('2025-10-09', '한글날'),
  ('2025-12-25', '크리스마스'),
  ('2026-01-01', '신정'),
  ('2026-02-16', '설날 연휴'),
  ('2026-02-17', '설날'),
  ('2026-02-18', '설날 연휴'),
  ('2026-03-01', '삼일절'),
  ('2026-03-02', '삼일절 대체공휴일'),
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


-- ============================================================
-- 10. posts
-- ============================================================

create table public.posts (
  id          uuid            default gen_random_uuid() primary key,
  user_id     uuid            references public.profiles(id) on delete set null,
  event_id    uuid            references public.events(id)   on delete set null,
  content     text,
  image_url   text,
  visibility  post_visibility not null default 'public',
  likes_count int             not null default 0,
  feed_date   date            not null,
  created_at  timestamptz     not null default now(),

  constraint posts_content_or_image check (content is not null or image_url is not null)
);

create index posts_feed_date_idx          on public.posts (feed_date desc);
create index posts_user_id_created_at_idx on public.posts (user_id, created_at desc);

alter table public.posts enable row level security;

create policy "posts: 본인 또는 친구 public 조회"
  on public.posts for select to authenticated
  using (
    user_id = auth.uid()
    or (
      visibility = 'public'
      and exists (
        select 1 from public.friends
        where user_id   = auth.uid()
          and friend_id = posts.user_id
      )
    )
  );

create policy "posts: 본인만 생성"
  on public.posts for insert to authenticated
  with check (user_id = auth.uid());

create policy "posts: 본인만 수정"
  on public.posts for update to authenticated
  using     (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "posts: 본인만 삭제"
  on public.posts for delete to authenticated
  using (user_id = auth.uid());


-- ============================================================
-- 11. post_likes
-- ============================================================

create table public.post_likes (
  post_id    uuid        references public.posts(id)    on delete cascade not null,
  user_id    uuid        references public.profiles(id) on delete cascade not null,
  created_at timestamptz not null default now(),

  primary key (post_id, user_id)
);

alter table public.post_likes enable row level security;

create policy "post_likes: 조회 가능한 게시글의 좋아요 조회"
  on public.post_likes for select to authenticated
  using (
    exists (
      select 1 from public.posts p
      where p.id = post_likes.post_id
        and (
          p.user_id = auth.uid()
          or (
            p.visibility = 'public'
            and exists (
              select 1 from public.friends f
              where f.user_id   = auth.uid()
                and f.friend_id = p.user_id
            )
          )
        )
    )
  );

create policy "post_likes: 본인이 좋아요 누르기"
  on public.post_likes for insert to authenticated
  with check (user_id = auth.uid());

create policy "post_likes: 본인 좋아요 취소"
  on public.post_likes for delete to authenticated
  using (user_id = auth.uid());


-- ── 트리거: likes_count 자동 집계 ────────────────────────────

create or replace function public.handle_post_like_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if TG_OP = 'INSERT' then
    update public.posts set likes_count = likes_count + 1         where id = new.post_id;
  elsif TG_OP = 'DELETE' then
    update public.posts set likes_count = greatest(0, likes_count - 1) where id = old.post_id;
  end if;
  return null;
end;
$$;

create trigger trg_post_like_count
  after insert or delete on public.post_likes
  for each row
  execute function public.handle_post_like_count();


-- ============================================================
-- 12. comments
-- ============================================================

create table public.comments (
  id         uuid        default gen_random_uuid() primary key,
  post_id    uuid        references public.posts(id)    on delete cascade not null,
  user_id    uuid        references public.profiles(id) on delete set null,
  content    text        not null,
  created_at timestamptz not null default now()
);

create index comments_post_id_created_at_idx on public.comments (post_id, created_at);

alter table public.comments enable row level security;

create policy "comments: 접근 가능한 게시글 댓글 조회"
  on public.comments for select to authenticated
  using (
    exists (
      select 1 from public.posts p
      where p.id = comments.post_id
        and (
          p.user_id = auth.uid()
          or (
            p.visibility = 'public'
            and exists (
              select 1 from public.friends
              where user_id   = auth.uid()
                and friend_id = p.user_id
            )
          )
        )
    )
  );

create policy "comments: 본인으로 댓글 생성"
  on public.comments for insert to authenticated
  with check (user_id = auth.uid());

create policy "comments: 본인 댓글 수정"
  on public.comments for update to authenticated
  using     (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "comments: 본인 댓글 삭제"
  on public.comments for delete to authenticated
  using (user_id = auth.uid());


-- ============================================================
-- 13. notifications
-- ============================================================

create table public.notifications (
  id         uuid              default gen_random_uuid() primary key,
  user_id    uuid              references public.profiles(id) on delete cascade not null,
  type       notification_type not null,
  title      text              not null,
  body       text              not null,
  is_read    boolean           not null default false,
  related_id uuid,
  created_at timestamptz       not null default now()
);

create index notifications_user_id_created_at_idx on public.notifications (user_id, created_at desc);
create index notifications_user_id_is_read_idx
  on public.notifications (user_id, is_read)
  where is_read = false;

alter table public.notifications enable row level security;

create policy "notifications: 본인만 조회"
  on public.notifications for select to authenticated
  using (user_id = auth.uid());

create policy "notifications: 본인만 읽음 처리"
  on public.notifications for update to authenticated
  using     (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "notifications: 본인만 삭제"
  on public.notifications for delete to authenticated
  using (user_id = auth.uid());

-- INSERT 정책 없음 → service_role(트리거/Edge Function)만 삽입 가능


-- ============================================================
-- 14. reports
-- ============================================================

create table public.reports (
  id           uuid               default gen_random_uuid() primary key,
  reporter_id  uuid               references public.profiles(id) on delete cascade not null,
  target_type  report_target_type not null,
  target_id    uuid               not null,
  reason       text               not null,
  status       report_status      not null default 'pending',
  created_at   timestamptz        not null default now(),

  constraint reports_unique unique (reporter_id, target_type, target_id)
);

create index reports_status_created_at_idx
  on public.reports (status, created_at)
  where status = 'pending';

create index reports_target_idx on public.reports (target_type, target_id);

alter table public.reports enable row level security;

create policy "reports: 본인으로 신고 접수"
  on public.reports for insert to authenticated
  with check (reporter_id = auth.uid());

create policy "reports: 본인 신고 내역 조회"
  on public.reports for select to authenticated
  using (reporter_id = auth.uid());

-- UPDATE / DELETE 정책 없음 — 관리자 service_role로만 처리


-- ============================================================
-- 15. RPC: free_slots (두 유저의 공통 빈 시간 계산)
-- ============================================================

create or replace function public.free_slots(
  p_user1_id       uuid,
  p_user2_id       uuid,
  p_from           timestamptz,
  p_to             timestamptz,
  p_min_minutes    int  default 60,
  p_day_start_hour int  default 9,
  p_day_end_hour   int  default 22,
  p_timezone       text default 'Asia/Seoul'
)
returns table(slot_start timestamptz, slot_end timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_day      date;
  v_ds       timestamptz;
  v_de       timestamptz;
  v_cursor   timestamptz;
  v_busy_end timestamptz;
  r          record;
begin
  v_day := (p_from at time zone p_timezone)::date;

  while v_day <= (p_to at time zone p_timezone)::date loop
    v_ds := (v_day::timestamp + make_interval(hours => p_day_start_hour)) at time zone p_timezone;
    v_de := (v_day::timestamp + make_interval(hours => p_day_end_hour))   at time zone p_timezone;
    v_ds := greatest(v_ds, p_from);
    v_de := least(v_de, p_to);

    if v_ds >= v_de then
      v_day := v_day + 1;
      continue;
    end if;

    v_cursor   := v_ds;
    v_busy_end := v_ds;

    for r in
      select greatest(start_at, v_ds) as bs, least(end_at, v_de) as be
      from public.events
      where user_id in (p_user1_id, p_user2_id)
        and start_at < v_de
        and end_at   > v_ds
      order by start_at
    loop
      if r.bs > v_busy_end then
        if extract(epoch from (r.bs - v_cursor)) >= p_min_minutes * 60 then
          slot_start := v_cursor;
          slot_end   := r.bs;
          return next;
        end if;
        v_cursor := r.bs;
      end if;
      if r.be > v_busy_end then
        v_busy_end := r.be;
        v_cursor   := v_busy_end;
      end if;
    end loop;

    if v_cursor < v_de then
      if extract(epoch from (v_de - v_cursor)) >= p_min_minutes * 60 then
        slot_start := v_cursor;
        slot_end   := v_de;
        return next;
      end if;
    end if;

    v_day := v_day + 1;
  end loop;
end;
$$;

grant execute on function public.free_slots to authenticated;
