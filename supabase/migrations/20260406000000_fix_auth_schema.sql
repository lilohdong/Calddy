-- ============================================================
-- Fix 1: handle_new_user 트리거
--   - new.email NULL 대응 (구글 계정 이메일 비공개 시 트리거 실패 방지)
--   - 임시 닉네임을 20자 이내로 축소 (Nickname VO의 maxLength와 일치)
-- ============================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, nickname, avatar_url, is_onboarded)
  values (
    new.id,
    coalesce(new.email, new.id || '@noemail.calddy'),
    -- 'u_' + UUID 앞 18자 = 20자 이내
    'u_' || substr(replace(new.id::text, '-', ''), 1, 18),
    new.raw_user_meta_data->>'avatar_url',
    false
  );
  return new;
end;
$$ language plpgsql security definer;

-- ============================================================
-- Fix 2: friendships — 자기 자신에게 친구 요청 차단
-- ============================================================
alter table public.friendships
  add constraint friendships_no_self_reference
  check (user_id_1 <> user_id_2);

-- ============================================================
-- Fix 3: schedules RLS — 'for all' 정책을 명시적 정책으로 분리
--   for all + using만 지정하면 INSERT의 with check가 암묵적으로 적용되어 모호하다.
--   INSERT / UPDATE / DELETE 를 명시적으로 분리한다.
-- ============================================================
drop policy if exists "내 일정만 관리 가능" on public.schedules;

create policy "내 일정만 생성 가능" on public.schedules
  for insert with check (auth.uid() = creator_id);

create policy "내 일정만 수정 가능" on public.schedules
  for update using (auth.uid() = creator_id);

create policy "내 일정만 삭제 가능" on public.schedules
  for delete using (auth.uid() = creator_id);
