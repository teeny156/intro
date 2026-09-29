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
