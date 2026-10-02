-- Supabase 대시보드 → SQL Editor 에 붙여넣고 Run 하세요.

create table if not exists public.guestbook (
  id         bigint generated always as identity primary key,
  name       text not null check (char_length(name) between 1 and 30),
  message    text not null check (char_length(message) between 1 and 300),
  created_at timestamptz not null default now()
);

-- 공개 역할에는 읽기/쓰기 권한만 부여 (수정·삭제 권한 없음)
grant select, insert on public.guestbook to anon, authenticated;

-- RLS: 누구나 읽기/쓰기만 가능, 수정·삭제는 불가 (대시보드에서만 관리)
alter table public.guestbook enable row level security;

drop policy if exists "guestbook read" on public.guestbook;
create policy "guestbook read"
  on public.guestbook for select
  to anon, authenticated
  using (true);

drop policy if exists "guestbook insert" on public.guestbook;
create policy "guestbook insert"
  on public.guestbook for insert
  to anon, authenticated
  with check (
    char_length(name) between 1 and 30
    and char_length(message) between 1 and 300
  );


-- ─────────────────────────────────────────────────────────────
-- 일정 관리: 누구나 보기, 편집은 schedule_editors 표에 등록된 계정만
-- 편집자 추가:  insert into public.schedule_editors (email) values ('친구@example.com');
-- 편집자 삭제:  delete from public.schedule_editors where email = '친구@example.com';
-- (계정·비밀번호는 Authentication → Users → Add user 에서 만듭니다)
-- ─────────────────────────────────────────────────────────────

create table if not exists public.schedules (
  id         bigint generated always as identity primary key,
  date       date not null,                -- 시작일
  end_date   date not null,                -- 종료일 (하루 일정이면 시작일과 같음)
  time       time,                         -- 시작 시간 (없으면 종일)
  end_time   time,                         -- 종료 시간 (선택)
  title      text not null check (char_length(title) between 1 and 60),
  memo       text check (memo is null or char_length(memo) <= 300),
  created_at timestamptz not null default now(),
  constraint schedules_end_after_start check (end_date >= date),
  constraint schedules_end_time_after_start
    check (end_date > date or time is null or end_time is null or end_time >= time)
);

create index if not exists schedules_date_idx on public.schedules (date);
create index if not exists schedules_end_date_idx on public.schedules (end_date);

grant select on public.schedules to anon, authenticated;
grant insert, update, delete on public.schedules to authenticated;

alter table public.schedules enable row level security;

drop policy if exists "schedules read" on public.schedules;
create policy "schedules read"
  on public.schedules for select
  to anon, authenticated
  using (true);

-- 편집 권한이 있는 계정 목록 (대시보드/SQL Editor 에서만 관리, 페이지에서는 읽기·쓰기 불가)
create table if not exists public.schedule_editors (
  email      text primary key,
  created_at timestamptz not null default now()
);
alter table public.schedule_editors enable row level security;
revoke all on public.schedule_editors from anon, authenticated;

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
