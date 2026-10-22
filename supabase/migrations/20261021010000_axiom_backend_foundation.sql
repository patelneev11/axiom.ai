-- Axiom backend foundation. Additive migration: preserves existing user_app_state and team tables.
begin;

create table if not exists public.axiom_lesson_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_slug text not null check (course_slug in ('hosa-biotechnology','hosa-biomedical-debate','deca-ftdm')),
  unit_number integer not null check (unit_number > 0),
  lesson_number integer not null check (lesson_number > 0),
  difficulty text not null check (difficulty in ('easy','medium','hard','expert')),
  correct_answers integer not null check (correct_answers >= 0),
  total_questions integer not null check (total_questions > 0 and correct_answers <= total_questions),
  duration_seconds integer not null default 0 check (duration_seconds >= 0),
  xp_earned integer not null default 0 check (xp_earned >= 0),
  completed_at timestamptz not null default now(),
  unique(user_id, course_slug, unit_number, lesson_number)
);

create table if not exists public.axiom_personal_calendar (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 120),
  details text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  course_slug text check (course_slug is null or course_slug in ('hosa-biotechnology','hosa-biomedical-debate','deca-ftdm')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at is null or ends_at >= starts_at)
);

create table if not exists public.axiom_team_resources (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.levelup_teams(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 120),
  resource_url text not null check (resource_url ~ '^https://'),
  description text,
  created_at timestamptz not null default now()
);

create index if not exists axiom_lesson_results_user_course_idx on public.axiom_lesson_results(user_id, course_slug);
create index if not exists axiom_calendar_user_start_idx on public.axiom_personal_calendar(user_id, starts_at);
create index if not exists axiom_team_resources_team_idx on public.axiom_team_resources(team_id);

alter table public.axiom_lesson_results enable row level security;
alter table public.axiom_personal_calendar enable row level security;
alter table public.axiom_team_resources enable row level security;

drop policy if exists "Users manage own lesson results" on public.axiom_lesson_results;
create policy "Users manage own lesson results" on public.axiom_lesson_results
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists "Users manage own personal calendar" on public.axiom_personal_calendar;
create policy "Users manage own personal calendar" on public.axiom_personal_calendar
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists "Team members view team resources" on public.axiom_team_resources;
create policy "Team members view team resources" on public.axiom_team_resources
  for select to authenticated using (public.is_levelup_team_member(team_id));

drop policy if exists "Team members add team resources" on public.axiom_team_resources;
create policy "Team members add team resources" on public.axiom_team_resources
  for insert to authenticated with check (created_by = (select auth.uid()) and public.is_levelup_team_member(team_id));

drop policy if exists "Team owners and admins manage team resources" on public.axiom_team_resources;
create policy "Team owners and admins manage team resources" on public.axiom_team_resources
  for delete to authenticated using (
    exists (select 1 from public.levelup_team_members m
      where m.team_id = axiom_team_resources.team_id
        and m.user_id = (select auth.uid())
        and m.role in ('owner','admin'))
  );

grant select, insert, update, delete on public.axiom_lesson_results to authenticated;
grant select, insert, update, delete on public.axiom_personal_calendar to authenticated;
grant select, insert, delete on public.axiom_team_resources to authenticated;

commit;
