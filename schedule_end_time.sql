-- 일정에 종료 시간(end_time) 추가: 시작(date, time) ~ 종료(end_date, end_time)
-- Supabase 대시보드 → SQL Editor → 이 파일 전체를 붙여넣고 Run.

alter table public.schedules add column if not exists end_time time;

-- 같은 날 일정이면 종료 시간이 시작 시간보다 앞설 수 없음
alter table public.schedules drop constraint if exists schedules_end_time_after_start;
alter table public.schedules add constraint schedules_end_time_after_start
  check (end_date > date or time is null or end_time is null or end_time >= time);

-- API가 새 열을 바로 인식하도록 갱신
notify pgrst, 'reload schema';

-- 확인용: end_time 열이 있으면 true
select exists (
  select 1 from information_schema.columns
  where table_schema = 'public' and table_name = 'schedules' and column_name = 'end_time'
) as end_time_ok;
