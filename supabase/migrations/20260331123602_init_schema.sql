-- 1. 프로필 테이블 (사용자 정보 및 온보딩 상태 관리)
create table public.profiles (
    id uuid references auth.users on delete cascade not null primary key,
    email text unique not null,
    nickname text unique not null,
    avatar_url text,
    is_onboarded boolean default false not null, -- 닉네임 설정 완료 여부
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. 일정 테이블 (캘린더 데이터)
create table public.schedules (
    id uuid default gen_random_uuid() primary key,
    creator_id uuid references public.profiles(id) on delete cascade not null,
    title text not null,
    description text,
    start_at timestamp with time zone not null,
    end_at timestamp with time zone not null,
    is_completed boolean default false not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. 친구 관계 테이블 (인스타 비공개 계정 스타일의 권한 기초)
create table public.friendships (
    id uuid default gen_random_uuid() primary key,
    user_id_1 uuid references public.profiles(id) on delete cascade not null,
    user_id_2 uuid references public.profiles(id) on delete cascade not null,
    status text check (status in ('pending', 'accepted')) default 'pending' not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(user_id_1, user_id_2)
);

-- 4. 보안 정책 (RLS) 설정

-- 모든 테이블 RLS 활성화
alter table public.profiles enable row level security;
alter table public.schedules enable row level security;
alter table public.friendships enable row level security;

-- [Profiles 정책]
-- 친구이거나 자기 자신인 경우만 프로필 조회 가능
create policy "친구 혹은 자신만 프로필 조회 가능" on public.profiles
    for select using (
        auth.uid() = id
        or exists (
            select 1 from public.friendships
            where (user_id_1 = auth.uid() and user_id_2 = profiles.id and status = 'accepted')
            or (user_id_1 = profiles.id and user_id_2 = auth.uid() and status = 'accepted')
        )
    );

-- 자신의 프로필만 수정 가능 (닉네임 설정 등)
create policy "자신의 프로필만 수정 가능" on public.profiles
    for update using (auth.uid() = id);

-- [Schedules 정책]
-- 내 일정 혹은 친구의 일정만 조회 가능
create policy "내 일정 혹은 친구 일정만 조회 가능" on public.schedules
    for select using (
        auth.uid() = creator_id
        or exists (
            select 1 from public.friendships
            where (user_id_1 = auth.uid() and user_id_2 = schedules.creator_id and status = 'accepted')
            or (user_id_1 = schedules.creator_id and user_id_2 = auth.uid() and status = 'accepted')
        )
    );

-- 내 일정만 생성/수정/삭제 가능
create policy "내 일정만 관리 가능" on public.schedules
    for all using (auth.uid() = creator_id);

-- [Friendships 정책]
-- 친구 관계에 연루된 당사자들만 조회 가능
create policy "친구 관계 당사자만 조회 가능" on public.friendships
    for select using (auth.uid() = user_id_1 or auth.uid() = user_id_2);

-- 누구나 친구 요청을 보낼 수 있음 (본인이 user_id_1인 경우만)
create policy "친구 요청 보내기 가능" on public.friendships
    for insert with check (auth.uid() = user_id_1);

-- 친구 요청 수락 혹은 거절 (당사자만 가능)
create policy "친구 요청 관리 가능" on public.friendships
    for update using (auth.uid() = user_id_1 or auth.uid() = user_id_2);

-- 5. 자동화 트리거 (구글 가입 시 프로필 자동 생성)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, nickname, avatar_url, is_onboarded)
  values (
    new.id, 
    new.email, 
    'user_' || replace(new.id::text, '-', ''), -- 중복 방지를 위한 UUID 기반 임시 닉네임
    new.raw_user_meta_data->>'avatar_url',
    false -- 초기 가입 시 온보딩 미완료 상태
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
