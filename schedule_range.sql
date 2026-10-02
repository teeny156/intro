-- 일정에 종료일(end_date) 추가: 시작일(date) ~ 종료일(end_date) 기간 일정
-- Supabase 대시보드 → SQL Editor → 이 파일 전체를 붙여넣고 Run.

alter table public.schedules add column if not exists end_date date;
update public.schedules set end_date = date where end_date is null;   -- 기존 일정은 하루짜리로
alter table public.schedules alter column end_date set not null;

alter table public.schedules drop constraint if exists schedules_end_after_start;
alter table public.schedules add constraint schedules_end_after_start check (end_date >= date);

create index if not exists schedules_end_date_idx on public.schedules (end_date);

-- API가 새 열을 바로 인식하도록 갱신
notify pgrst, 'reload schema';

-- 확인용: end_date 열이 있으면 true
select exists (
  select 1 from information_schema.columns
  where table_schema = 'public' and table_name = 'schedules' and column_name = 'end_date'
) as end_date_ok;
