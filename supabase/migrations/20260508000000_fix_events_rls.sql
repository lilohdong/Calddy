-- RLS UPDATE 정책에 WITH CHECK 추가
-- user_id를 다른 사용자 ID로 변경하는 UPDATE를 차단 (소유권 이전 방지)
alter policy "본인 일정만 수정" on public.events
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
