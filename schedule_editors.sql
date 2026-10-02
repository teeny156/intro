-- 일정 편집 권한을 "관리자 1명"에서 "등록된 편집자 계정들"로 변경
-- Supabase 대시보드 → (주소가 ywggtsezqmyaddslqdvh 인 프로젝트) → SQL Editor
-- → New query → 이 파일 전체를 붙여넣고 Run.
-- 맨 아래 결과 칸에 편집자 목록이 나오면 성공입니다.
--
-- 이후 편집자 추가/삭제는 SQL Editor 에서:
--   insert into public.schedule_editors (email) values ('친구@example.com');
--   delete from public.schedule_editors where email = '친구@example.com';
-- 해당 이메일의 계정·비밀번호는 Authentication → Users → Add user 에서 만듭니다
-- (Auto Confirm User 체크). 페이지에서는 '@' 앞 아이디만 입력해도 @naver.com 으로 로그인됩니다.
--
-- 이미 있는 계정의 비밀번호를 SQL로 직접 정하려면 (비밀번호는 이 파일에 저장하지 말고 SQL Editor 에서만 입력):
--   update auth.users
--      set encrypted_password = extensions.crypt('새비밀번호', extensions.gen_salt('bf'))
--    where email = 'teeny156@naver.com';
-- 로그인한 뒤에는 페이지의 "🔑 비밀번호 변경" 버튼으로 언제든 바꿀 수 있습니다.

-- 편집 권한이 있는 계정 목록 (대시보드/SQL Editor 에서만 관리, 페이지에서는 읽기·쓰기 불가)
create table if not exists public.schedule_editors (
  email      text primary key,
  created_at timestamptz not null default now()
);
alter table public.schedule_editors enable row level security;
revoke all on public.schedule_editors from anon, authenticated;

-- 기존 관리자 계정도 편집자로 유지 (원치 않으면 이 줄을 지우세요)
insert into public.schedule_editors (email) values ('teeny156@naver.com')
  on conflict do nothing;

-- 로그인한 계정이 편집자인지 (페이지와 RLS 정책이 함께 사용)
create or replace function public.is_schedule_editor()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.schedule_editors
    where lower(email) = lower(auth.jwt() ->> 'email')
  );
$$;
revoke execute on function public.is_schedule_editor() from public, anon;
grant execute on function public.is_schedule_editor() to authenticated;

-- 기존 "관리자 이메일 고정" 정책 제거 후 편집자 기준 정책으로 교체
drop policy if exists "schedules admin insert" on public.schedules;
drop policy if exists "schedules admin update" on public.schedules;
drop policy if exists "schedules admin delete" on public.schedules;

drop policy if exists "schedules editor insert" on public.schedules;
create policy "schedules editor insert"
  on public.schedules for insert
  to authenticated
  with check (public.is_schedule_editor());

drop policy if exists "schedules editor update" on public.schedules;
create policy "schedules editor update"
  on public.schedules for update
  to authenticated
  using (public.is_schedule_editor())
  with check (public.is_schedule_editor());

drop policy if exists "schedules editor delete" on public.schedules;
create policy "schedules editor delete"
  on public.schedules for delete
  to authenticated
  using (public.is_schedule_editor());

-- API가 새 함수를 바로 인식하도록 갱신
notify pgrst, 'reload schema';

-- 확인용: 현재 편집자 목록
select email, created_at from public.schedule_editors order by created_at;
