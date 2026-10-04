-- 방명록 글 삭제: 로그인한 편집자(schedule_editors 표에 있는 계정)만 가능
-- Supabase 대시보드 → SQL Editor → 이 파일 전체를 붙여넣고 Run.

grant delete on public.guestbook to authenticated;

drop policy if exists "guestbook editor delete" on public.guestbook;
create policy "guestbook editor delete"
  on public.guestbook for delete
  to authenticated
  using (public.is_schedule_editor());

-- 확인용: 정책이 있으면 true
select exists (
  select 1 from pg_policies
  where schemaname = 'public' and tablename = 'guestbook' and policyname = 'guestbook editor delete'
) as guestbook_delete_ok;
