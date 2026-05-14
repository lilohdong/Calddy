-- ============================================================
-- notifications 테이블
--
-- 알림 생성(INSERT)은 DB 트리거 또는 Edge Function만 가능.
-- RLS INSERT 정책 없음 → 클라이언트 직접 INSERT 차단.
-- Flutter는 SELECT / UPDATE(읽음 처리) / DELETE만 호출.
--
-- Realtime 구독으로 신규 알림 즉시 수신:
--   supabase.channel('notifications')
--     .on('postgres_changes', { event: 'INSERT', table: 'notifications',
--          filter: 'user_id=eq.<uid>' }, handler)
--     .subscribe()
-- ============================================================


-- ============================================================
-- 1. Enum
-- ============================================================

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


-- ============================================================
-- 2. notifications 테이블
-- ============================================================

create table if not exists public.notifications (
  id         uuid              default gen_random_uuid() primary key,
  user_id    uuid              references public.profiles(id) on delete cascade not null,
  type       notification_type not null,
  title      text              not null,
  body       text              not null,
  is_read    boolean           not null default false,
  -- 관련 리소스 ID (friend_request_id, post_id, appointment_id 등)
  related_id uuid,
  created_at timestamptz       default now() not null
);


-- ============================================================
-- 3. 인덱스
-- ============================================================

-- 최신 알림 목록 조회
create index if not exists notifications_user_id_created_at_idx
  on public.notifications (user_id, created_at desc);

-- 읽지 않은 알림 배지 카운트
create index if not exists notifications_user_id_is_read_idx
  on public.notifications (user_id, is_read)
  where is_read = false;


-- ============================================================
-- 4. RLS
-- ============================================================

alter table public.notifications enable row level security;

-- SELECT: 본인 알림만
create policy "notifications: 본인만 조회"
  on public.notifications for select to authenticated
  using (user_id = auth.uid());

-- UPDATE: 읽음 상태 변경 (is_read = true)
create policy "notifications: 본인만 읽음 처리"
  on public.notifications for update to authenticated
  using     (user_id = auth.uid())
  with check (user_id = auth.uid());

-- DELETE: 본인 알림 삭제
create policy "notifications: 본인만 삭제"
  on public.notifications for delete to authenticated
  using (user_id = auth.uid());

-- INSERT 정책 없음 → service_role(트리거/Edge Function)만 삽입 가능
