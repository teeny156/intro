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
-- 일정 관리: 누구나 보기, 편집은 관리자(아래 이메일로 로그인한 계정)만
-- 관리자 이메일을 바꾸려면 'teeny156@naver.com' 세 군데를 모두 바꾸세요.
-- ─────────────────────────────────────────────────────────────

create table if not exists public.schedules (
  id         bigint generated always as identity primary key,
  date       date not null,
  time       time,
  title      text not null check (char_length(title) between 1 and 60),
  memo       text check (memo is null or char_length(memo) <= 300),
  created_at timestamptz not null default now()
);

create index if not exists schedules_date_idx on public.schedules (date);

grant select on public.schedules to anon, authenticated;
grant insert, update, delete on public.schedules to authenticated;

alter table public.schedules enable row level security;

drop policy if exists "schedules read" on public.schedules;
create policy "schedules read"
  on public.schedules for select
  to anon, authenticated
  using (true);

drop policy if exists "schedules admin insert" on public.schedules;
create policy "schedules admin insert"
  on public.schedules for insert
  to authenticated
  with check ((auth.jwt() ->> 'email') = 'teeny156@naver.com');

drop policy if exists "schedules admin update" on public.schedules;
create policy "schedules admin update"
  on public.schedules for update
  to authenticated
  using ((auth.jwt() ->> 'email') = 'teeny156@naver.com')
  with check ((auth.jwt() ->> 'email') = 'teeny156@naver.com');

drop policy if exists "schedules admin delete" on public.schedules;
create policy "schedules admin delete"
  on public.schedules for delete
  to authenticated
  using ((auth.jwt() ->> 'email') = 'teeny156@naver.com');
