-- ============================================================
-- Friend 기능 마이그레이션
--
-- 변경 사항:
--   1. profiles.bio 컬럼 추가 (친구 검색 한줄 소개 표시)
--   2. friendships 테이블 제거 (Flutter 코드와 불일치)
--      → friend_requests + friends 로 분리
--   3. 인덱스
--   4. RLS (friend_requests / friends)
--   5. RLS 업데이트 (profiles / events — friendships 참조 → friends 로 교체)
--   6. 트리거: friend_requests 수락 → friends 양방향 INSERT
--   7. RPC: free_slots — 두 유저의 공통 빈 시간 계산
-- ============================================================


-- ============================================================
-- 1. profiles.bio 추가
-- ============================================================

alter table public.profiles
  add column if not exists bio text;


-- ============================================================
-- 2. friendships 기존 RLS 정책 제거
--    (아래에서 friends 테이블 기반으로 재작성)
-- ============================================================

drop policy if exists "친구 혹은 자신만 프로필 조회 가능"   on public.profiles;
drop policy if exists "본인 또는 친구 public 일정 조회"    on public.events;
drop policy if exists "친구 관계 당사자만 조회 가능"        on public.friendships;
drop policy if exists "친구 요청 보내기 가능"              on public.friendships;
drop policy if exists "친구 요청 관리 가능"                on public.friendships;


-- ============================================================
-- 3. friendships 테이블 제거
--    (초기 개발 단계 — 실 데이터 없음)
-- ============================================================

drop table if exists public.friendships cascade;


-- ============================================================
-- 4. friend_requests 테이블
--    requester  : 요청을 보낸 유저
--    addressee  : 요청을 받은 유저
--    status     : pending | accepted | rejected
-- ============================================================

create table public.friend_requests (
  id            uuid        default gen_random_uuid() primary key,
  requester_id  uuid        references public.profiles(id) on delete cascade not null,
  addressee_id  uuid        references public.profiles(id) on delete cascade not null,
  status        text        not null default 'pending'
                            check (status in ('pending', 'accepted', 'rejected')),
  created_at    timestamptz default now() not null,

  -- 같은 방향 중복 요청 방지
  constraint friend_requests_unique unique (requester_id, addressee_id),
  -- 자기 자신에게 요청 금지
  constraint friend_requests_no_self check (requester_id <> addressee_id)
);


-- ============================================================
-- 5. friends 테이블
--    수락된 친구 관계를 양방향으로 저장 (트리거가 INSERT)
--    user_id → friend_id 단방향 행, 반대 방향 행 각각 존재
-- ============================================================

create table public.friends (
  user_id     uuid        references public.profiles(id) on delete cascade not null,
  friend_id   uuid        references public.profiles(id) on delete cascade not null,
  created_at  timestamptz default now() not null,

  primary key (user_id, friend_id),
  constraint friends_no_self check (user_id <> friend_id)
);


-- ============================================================
-- 6. 인덱스
-- ============================================================

-- friend_requests 조회: 나에게 온 요청 목록 (addressee 기준)
create index friend_requests_addressee_status_idx
  on public.friend_requests (addressee_id, status);

-- friend_requests 조회: 내가 보낸 요청 목록 (requester 기준)
create index friend_requests_requester_status_idx
  on public.friend_requests (requester_id, status);

-- friends 조회: 내 친구 목록
create index friends_user_id_idx
  on public.friends (user_id);


-- ============================================================
-- 7. RLS 활성화
-- ============================================================

alter table public.friend_requests enable row level security;
alter table public.friends         enable row level security;


-- ============================================================
-- 8. friend_requests RLS
-- ============================================================

-- 조회: 나와 관련된 요청만
create policy "friend_requests: 당사자 조회"
  on public.friend_requests for select
  to authenticated
  using (requester_id = auth.uid() or addressee_id = auth.uid());

-- 생성: 본인이 requester (UNIQUE 제약이 중복 요청 차단)
create policy "friend_requests: 본인이 요청자로 생성"
  on public.friend_requests for insert
  to authenticated
  with check (requester_id = auth.uid());

-- 수정: 수신자만 status 변경 (수락/거절)
create policy "friend_requests: 수신자만 상태 변경"
  on public.friend_requests for update
  to authenticated
  using     (addressee_id = auth.uid())
  with check (addressee_id = auth.uid());

-- 삭제: 요청자 본인만 (요청 취소)
create policy "friend_requests: 요청자만 삭제"
  on public.friend_requests for delete
  to authenticated
  using (requester_id = auth.uid());


-- ============================================================
-- 9. friends RLS
-- ============================================================

-- 조회: 나와 관련된 친구 관계만
create policy "friends: 당사자 조회"
  on public.friends for select
  to authenticated
  using (user_id = auth.uid() or friend_id = auth.uid());

-- 삭제: 나와 관련된 행 (양방향 삭제 허용)
create policy "friends: 당사자 삭제"
  on public.friends for delete
  to authenticated
  using (user_id = auth.uid() or friend_id = auth.uid());

-- INSERT: 직접 삽입 불가 — 트리거(SECURITY DEFINER)만 허용
-- (INSERT 정책 없음 → RLS가 기본 차단, SECURITY DEFINER 트리거는 RLS 우회)


-- ============================================================
-- 10. profiles RLS 재작성 (friends 테이블 기반)
--     친구 검색을 위해 모든 인증 유저가 profiles 조회 가능
-- ============================================================

create policy "profiles: 인증 유저 전체 조회"
  on public.profiles for select
  to authenticated
  using (true);

create policy "profiles: 본인만 수정"
  on public.profiles for update
  to authenticated
  using     (id = auth.uid())
  with check (id = auth.uid());


-- ============================================================
-- 11. events RLS 재작성 (friends 테이블 기반)
-- ============================================================

create policy "events: 본인 또는 친구 public 일정 조회"
  on public.events for select
  to authenticated
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


-- ============================================================
-- 12. 트리거: friend_requests 수락 → friends 양방향 INSERT
-- ============================================================

create or replace function public.handle_friend_request_accepted()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- pending → accepted 로 전환되는 순간에만 실행
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

drop trigger if exists trg_friend_request_accepted on public.friend_requests;

create trigger trg_friend_request_accepted
  after update of status on public.friend_requests
  for each row
  execute function public.handle_friend_request_accepted();


-- ============================================================
-- 13. RPC: free_slots
--
-- 두 유저가 모두 비어있는 시간대를 반환한다.
--
-- 파라미터:
--   p_user1_id       : 첫 번째 유저 UUID
--   p_user2_id       : 두 번째 유저 UUID
--   p_from           : 탐색 시작 시각 (TIMESTAMPTZ)
--   p_to             : 탐색 종료 시각 (TIMESTAMPTZ)
--   p_min_minutes    : 최소 슬롯 길이(분), 기본 60
--   p_day_start_hour : 하루 시작 시각(시), 기본 9
--   p_day_end_hour   : 하루 종료 시각(시), 기본 22
--   p_timezone       : 타임존, 기본 'Asia/Seoul'
--
-- 반환:
--   slot_start TIMESTAMPTZ, slot_end TIMESTAMPTZ
--
-- 알고리즘:
--   1. 타임존 기준으로 날짜를 하루씩 순회
--   2. 해당 날짜의 하루 시작/종료를 UTC TIMESTAMPTZ 로 변환
--   3. 두 유저의 events 를 시작 시간 순으로 가져와 병합
--   4. 병합된 busy 구간 사이의 틈새(free slot)를 추출
--   5. 최소 길이 이상인 슬롯만 반환
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
  v_ds       timestamptz;  -- 해당 일 시작 (UTC)
  v_de       timestamptz;  -- 해당 일 종료 (UTC)
  v_cursor   timestamptz;  -- 현재 탐색 위치
  v_busy_end timestamptz;  -- 병합된 busy 구간 끝
  r          record;
begin
  -- 타임존 기준 날짜로 시작
  v_day := (p_from at time zone p_timezone)::date;

  while v_day <= (p_to at time zone p_timezone)::date loop

    -- 하루 시작/종료를 해당 타임존 기준으로 계산 후 UTC TIMESTAMPTZ 로 변환
    v_ds := (v_day::timestamp + make_interval(hours => p_day_start_hour))
              at time zone p_timezone;
    v_de := (v_day::timestamp + make_interval(hours => p_day_end_hour))
              at time zone p_timezone;

    -- 요청 범위로 클리핑
    v_ds := greatest(v_ds, p_from);
    v_de := least(v_de, p_to);

    if v_ds >= v_de then
      v_day := v_day + 1;
      continue;
    end if;

    v_cursor   := v_ds;
    v_busy_end := v_ds;

    -- 두 유저의 이벤트를 시작 시간 순으로 순회하며 busy 구간 병합
    for r in
      select
        greatest(start_at, v_ds) as bs,
        least(end_at,      v_de) as be
      from public.events
      where user_id in (p_user1_id, p_user2_id)
        and start_at < v_de
        and end_at   > v_ds
      order by start_at
    loop
      if r.bs > v_busy_end then
        -- busy 구간 앞에 틈새 존재 → free slot 후보
        if extract(epoch from (r.bs - v_cursor)) >= p_min_minutes * 60 then
          slot_start := v_cursor;
          slot_end   := r.bs;
          return next;
        end if;
        v_cursor := r.bs;
      end if;

      -- 겹치는 이벤트를 하나의 busy 구간으로 병합
      if r.be > v_busy_end then
        v_busy_end := r.be;
        v_cursor   := v_busy_end;
      end if;
    end loop;

    -- 마지막 busy 구간 이후 남은 시간 확인
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

-- 인증된 유저에게 RPC 호출 권한 부여
grant execute on function public.free_slots to authenticated;
