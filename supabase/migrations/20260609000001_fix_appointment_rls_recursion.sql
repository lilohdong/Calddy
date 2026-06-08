-- Fix: appointments ↔ appointment_invites 교차 RLS 무한 재귀 해결
--
-- 원인: appointments SELECT 정책이 appointment_invites를 조회하고,
--       appointment_invites SELECT 정책이 다시 appointments를 조회하면서
--       무한 재귀 발생.
--
-- 해결: security definer 헬퍼 함수로 appointment_invites 조회를 RLS 우회 실행.

-- 1. 헬퍼 함수 생성
create or replace function public.is_appointment_invitee(appt_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.appointment_invites
    where appointment_id = appt_id
      and invitee_id = auth.uid()
  );
$$;

-- 2. 기존 정책 교체
drop policy if exists "약속 조회: creator 또는 초대받은 사람" on public.appointments;

create policy "약속 조회: creator 또는 초대받은 사람"
  on public.appointments for select using (
    auth.uid() = creator_id
    or public.is_appointment_invitee(id)
  );
