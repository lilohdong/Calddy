-- ============================================================
-- Notification Triggers v2
--
-- app.settings.* 대신 private.secrets 테이블 방식으로 변경.
-- (Supabase 관리형 PostgreSQL에서 ALTER DATABASE SET app.settings.*
--  는 superuser 권한 부족으로 실행 불가)
--
-- 사전 설정 필요 (1회, 대시보드 SQL Editor):
--   INSERT INTO private.secrets (key, value)
--   VALUES ('service_role_key', '<service_role_key>');
--
-- 미설정 시: notifications 행은 정상 기록되고 FCM 호출만 skip됨.
-- ============================================================

-- service_role_key 보관용 테이블
create table if not exists private.secrets (
  key   text primary key,
  value text not null
);

-- public/anon/authenticated 접근 차단
revoke all on private.secrets from public, anon, authenticated;

-- send_push_notification 업데이트:
--   URL 하드코딩 (공개값) + service_role_key는 private.secrets에서 조회
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
set search_path = public, private
as $$
declare
  v_url text := 'https://iqcmtcmlfhplnepnmtfl.supabase.co';
  v_key text;
begin
  -- 1. notifications 행 INSERT (동기 — 실패 시 호출 트랜잭션 롤백)
  insert into public.notifications (user_id, type, title, body, related_id)
  values (p_user_id, p_type, p_title, p_body, p_related_id);

  -- 2. service_role_key 조회
  select value into v_key from private.secrets where key = 'service_role_key';

  -- 3. Edge Function 비동기 호출 (best-effort — 실패해도 트랜잭션 롤백 없음)
  if v_key is not null then
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

grant usage on schema private to postgres, supabase_admin, service_role;
grant all on private.secrets to postgres, supabase_admin, service_role;
grant execute
  on function private.send_push_notification(uuid, public.notification_type, text, text, uuid)
  to postgres, supabase_admin, service_role;
