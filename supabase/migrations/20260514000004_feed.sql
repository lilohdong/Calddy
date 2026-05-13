-- ============================================================
-- Feed 기능: posts / post_likes / comments
--
-- posts:
--   - user_id ON DELETE SET NULL: 탈퇴 후 게시글 익명 보존
--   - event_id ON DELETE SET NULL: 일정 삭제 후 게시글 유지
--   - likes_count: DB 트리거(trg_post_like_count)로 자동 집계
--
-- post_likes:
--   - PK(post_id, user_id): UNIQUE 중복 좋아요 방지
--   - RLS INSERT 정책 없음: 트리거가 likes_count 갱신하는 전용 경로만 허용
--     → 클라이언트는 post_likes에 직접 INSERT 대신 upsert 사용
--     (실제로 INSERT RLS가 있어야 클라이언트가 좋아요 누를 수 있음 — 아래 명시)
--
-- comments:
--   - user_id ON DELETE SET NULL: 탈퇴 후 '[삭제된 댓글]' 처리는 withdrawal Edge Function
--   - RLS SELECT: 해당 post를 볼 수 있는 유저만
-- ============================================================


-- ============================================================
-- 1. Enum
-- ============================================================

do $$ begin
  create type post_visibility as enum ('public', 'private');
exception when duplicate_object then null;
end $$;


-- ============================================================
-- 2. posts 테이블
-- ============================================================

create table if not exists public.posts (
  id          uuid            default gen_random_uuid() primary key,
  -- 탈퇴 시 SET NULL (게시글 내용은 익명으로 보존)
  user_id     uuid            references public.profiles(id) on delete set null,
  -- 연동된 일정 삭제 시 SET NULL (게시글 자체는 유지)
  event_id    uuid            references public.events(id)   on delete set null,
  content     text,
  image_url   text,
  visibility  post_visibility not null default 'public',
  likes_count int             not null default 0,
  feed_date   date            not null,
  created_at  timestamptz     default now() not null,

  -- 텍스트 또는 이미지 중 하나 이상 필수
  constraint posts_content_or_image check (content is not null or image_url is not null)
);

-- 날짜별 피드 조회
create index if not exists posts_feed_date_idx
  on public.posts (feed_date desc);

-- 내 게시글 목록 조회
create index if not exists posts_user_id_created_at_idx
  on public.posts (user_id, created_at desc);

alter table public.posts enable row level security;

-- SELECT: 본인 전체 + 친구의 public 게시글
-- (friends 테이블은 20260513 friends_restructure 마이그레이션에서 생성됨)
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
-- 3. post_likes 테이블
-- ============================================================

create table if not exists public.post_likes (
  post_id    uuid        references public.posts(id)    on delete cascade not null,
  user_id    uuid        references public.profiles(id) on delete cascade not null,
  created_at timestamptz default now() not null,

  primary key (post_id, user_id)
);

alter table public.post_likes enable row level security;

create policy "post_likes: 본인 좋아요 조회"
  on public.post_likes for select to authenticated
  using (user_id = auth.uid());

create policy "post_likes: 본인이 좋아요 누르기"
  on public.post_likes for insert to authenticated
  with check (user_id = auth.uid());

create policy "post_likes: 본인 좋아요 취소"
  on public.post_likes for delete to authenticated
  using (user_id = auth.uid());


-- ============================================================
-- 4. likes_count 자동 집계 트리거
-- ============================================================

create or replace function public.handle_post_like_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if TG_OP = 'INSERT' then
    update public.posts
    set likes_count = likes_count + 1
    where id = new.post_id;
  elsif TG_OP = 'DELETE' then
    update public.posts
    -- 음수 방지
    set likes_count = greatest(0, likes_count - 1)
    where id = old.post_id;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_post_like_count on public.post_likes;

create trigger trg_post_like_count
  after insert or delete on public.post_likes
  for each row
  execute function public.handle_post_like_count();


-- ============================================================
-- 5. comments 테이블
-- ============================================================

create table if not exists public.comments (
  id         uuid        default gen_random_uuid() primary key,
  post_id    uuid        references public.posts(id)    on delete cascade not null,
  -- 탈퇴 시 SET NULL, 내용 처리는 withdrawal Edge Function
  user_id    uuid        references public.profiles(id) on delete set null,
  content    text        not null,
  created_at timestamptz default now() not null
);

-- 게시글별 댓글 목록 조회
create index if not exists comments_post_id_created_at_idx
  on public.comments (post_id, created_at);

alter table public.comments enable row level security;

-- SELECT: 해당 post를 볼 수 있는 유저만
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

-- INSERT: 인증 유저, 본인이 user_id인 경우만
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
