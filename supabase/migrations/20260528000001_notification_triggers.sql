-- ============================================================
-- Notification Triggers
--
-- 알림 생성 파이프라인:
--   DB 이벤트 → notifications INSERT (동기)
--             → net.http_post → send-notification Edge Fn (비동기)
--
-- 사전 설정 필요 (1회, 대시보드 SQL Editor):
--   ALTER DATABASE postgres SET app.settings.supabase_url TO 'https://<ref>.supabase.co';
--   ALTER DATABASE postgres SET app.settings.service_role_key TO '<key>';
--
-- 미설정 시: notifications 행은 정상 기록되고 FCM 호출만 skip됨.
-- ============================================================


-- pg_net 확장 (Supabase 기본 제공, 스키마 net)
create extension if not exists pg_net;

-- private 스키마 (헬퍼 함수 격리)
create schema if not exists private;


-- ============================================================
-- 공통 헬퍼: notifications INSERT + FCM 비동기 호출
-- ============================================================

create or replace function private.send_push_notification(
  p_user_id    uuid,
  p_type       public.notification_type,
  p_title      text,
  p_body       text,
  p_related_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_url text := current_setting('app.settings.supabase_url', true);
  v_key text := current_setting('app.settings.service_role_key', true);
begin
  -- 1. notifications 행 INSERT (동기 — 실패 시 호출 트랜잭션 롤백)
  insert into public.notifications (user_id, type, title, body, related_id)
  values (p_user_id, p_type, p_title, p_body, p_related_id);

  -- 2. Edge Function 비동기 호출 (best-effort — 실패해도 트랜잭션 롤백 없음)
  if v_url is not null and v_key is not null then
    begin
      perform net.http_post(
        url     := v_url || '/functions/v1/send-notification',
        headers := jsonb_build_object(
          'Content-Type',  'application/json',
          'Authorization', 'Bearer ' || v_key
        ),
        body    := jsonb_build_object(
          'userId',    p_user_id,
          'type',      p_type::text,
          'title',     p_title,
          'body',      p_body,
          'relatedId', p_related_id
        )
      );
    exception
      when others then
        raise warning '[send_push_notification] pg_net failed: %', sqlerrm;
    end;
  end if;
end;
$$;


-- ============================================================
-- 트리거 1: 친구 요청 수신
--   friend_requests INSERT → friend_request → addressee
-- ============================================================

create or replace function public.notify_on_friend_request()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_nickname text;
begin
  select nickname into v_nickname
  from public.profiles
  where id = new.requester_id;

  if v_nickname is null then
    return new;
  end if;

  perform private.send_push_notification(
    p_user_id    := new.addressee_id,
    p_type       := 'friend_request'::public.notification_type,
    p_title      := '친구 요청이 왔어요',
    p_body       := v_nickname || '님이 친구 요청을 보냈습니다.',
    p_related_id := new.id
  );

  return new;
end;
$$;

create trigger trg_notify_friend_request
  after insert on public.friend_requests
  for each row
  execute function public.notify_on_friend_request();


-- ============================================================
-- 트리거 2: 약속 초대 수신
--   appointment_invites INSERT → appointment_invite → invitee
-- ============================================================

create or replace function public.notify_on_appointment_invite()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_nickname   text;
  v_creator_id uuid;
begin
  select creator_id into v_creator_id
  from public.appointments
  where id = new.appointment_id;

  if v_creator_id is null then
    return new;
  end if;

  select nickname into v_nickname
  from public.profiles
  where id = v_creator_id;

  if v_nickname is null then
    return new;
  end if;

  perform private.send_push_notification(
    p_user_id    := new.invitee_id,
    p_type       := 'appointment_invite'::public.notification_type,
    p_title      := '약속 초대가 왔어요',
    p_body       := v_nickname || '님이 약속에 초대했습니다.',
    p_related_id := new.appointment_id
  );

  return new;
end;
$$;

create trigger trg_notify_appointment_invite
  after insert on public.appointment_invites
  for each row
  execute function public.notify_on_appointment_invite();


-- ============================================================
-- 트리거 3: 약속 수락 / 거절
--   appointment_invites UPDATE
--     → accepted  : appointment_accepted → creator
--     → rejected  : appointment_rejected + suggest_new_date → creator
-- ============================================================

create or replace function public.notify_on_appointment_status_change()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_nickname   text;
  v_creator_id uuid;
begin
  if old.status is not distinct from new.status then
    return new;
  end if;

  select creator_id into v_creator_id
  from public.appointments
  where id = new.appointment_id;

  if v_creator_id is null then
    return new;
  end if;

  select nickname into v_nickname
  from public.profiles
  where id = new.invitee_id;

  if v_nickname is null then
    return new;
  end if;

  if new.status = 'accepted' then
    perform private.send_push_notification(
      p_user_id    := v_creator_id,
      p_type       := 'appointment_accepted'::public.notification_type,
      p_title      := '약속이 수락됐어요',
      p_body       := v_nickname || '님이 약속을 수락했습니다.',
      p_related_id := new.appointment_id
    );

  elsif new.status = 'rejected' then
    perform private.send_push_notification(
      p_user_id    := v_creator_id,
      p_type       := 'appointment_rejected'::public.notification_type,
      p_title      := '약속이 거절됐어요',
      p_body       := v_nickname || '님이 약속을 거절했습니다.',
      p_related_id := new.appointment_id
    );

    perform private.send_push_notification(
      p_user_id    := v_creator_id,
      p_type       := 'suggest_new_date'::public.notification_type,
      p_title      := '다른 날짜를 제안해보세요',
      p_body       := v_nickname || '님이 다른 시간을 원합니다.',
      p_related_id := new.appointment_id
    );
  end if;

  return new;
end;
$$;

create trigger trg_notify_appointment_status_change
  after update of status on public.appointment_invites
  for each row
  execute function public.notify_on_appointment_status_change();


-- ============================================================
-- 트리거 4: 게시글 좋아요
--   post_likes INSERT → post_liked → post 작성자
--   (본인 게시글 본인 좋아요 시 skip)
-- ============================================================

create or replace function public.notify_on_post_like()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_post_owner uuid;
  v_nickname   text;
begin
  select user_id into v_post_owner
  from public.posts
  where id = new.post_id;

  if v_post_owner is null or new.user_id = v_post_owner then
    return new;
  end if;

  select nickname into v_nickname
  from public.profiles
  where id = new.user_id;

  if v_nickname is null then
    return new;
  end if;

  perform private.send_push_notification(
    p_user_id    := v_post_owner,
    p_type       := 'post_liked'::public.notification_type,
    p_title      := '좋아요를 받았어요',
    p_body       := v_nickname || '님이 회원님의 게시글을 좋아합니다.',
    p_related_id := new.post_id
  );

  return new;
end;
$$;

create trigger trg_notify_post_like
  after insert on public.post_likes
  for each row
  execute function public.notify_on_post_like();


-- ============================================================
-- 트리거 5: 댓글
--   comments INSERT → post_commented → post 작성자
--   (본인 게시글 본인 댓글 시 skip)
-- ============================================================

create or replace function public.notify_on_comment()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_post_owner uuid;
  v_nickname   text;
begin
  select user_id into v_post_owner
  from public.posts
  where id = new.post_id;

  if v_post_owner is null or new.user_id = v_post_owner then
    return new;
  end if;

  select nickname into v_nickname
  from public.profiles
  where id = new.user_id;

  if v_nickname is null then
    return new;
  end if;

  perform private.send_push_notification(
    p_user_id    := v_post_owner,
    p_type       := 'post_commented'::public.notification_type,
    p_title      := '댓글이 달렸어요',
    p_body       := v_nickname || '님이 댓글을 남겼습니다.',
    p_related_id := new.post_id
  );

  return new;
end;
$$;

create trigger trg_notify_comment
  after insert on public.comments
  for each row
  execute function public.notify_on_comment();


-- ============================================================
-- GRANT
-- ============================================================

grant usage on schema private to postgres, supabase_admin, service_role;
grant execute
  on function private.send_push_notification(uuid, public.notification_type, text, text, uuid)
  to postgres, supabase_admin, service_role;
