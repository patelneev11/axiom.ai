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

create table if not exists public.axiom_user_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  xp integer not null default 0 check (xp >= 0),
  hearts integer not null default 5 check (hearts between 0 and 5),
  heart_updated_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
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
alter table public.axiom_user_progress enable row level security;
alter table public.axiom_personal_calendar enable row level security;
alter table public.axiom_team_resources enable row level security;

drop policy if exists "Users manage own lesson results" on public.axiom_lesson_results;
drop policy if exists "Users view own lesson results" on public.axiom_lesson_results;
create policy "Users view own lesson results" on public.axiom_lesson_results
  for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists "Users view own progression" on public.axiom_user_progress;
create policy "Users view own progression" on public.axiom_user_progress
  for select to authenticated using (user_id = (select auth.uid()));

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

grant select on public.axiom_lesson_results to authenticated;
grant select on public.axiom_user_progress to authenticated;
grant select, insert, update, delete on public.axiom_personal_calendar to authenticated;
grant select, insert, delete on public.axiom_team_resources to authenticated;

revoke insert, update, delete on public.axiom_user_progress from anon, authenticated;
revoke insert, update, delete on public.axiom_lesson_results from anon, authenticated;

create or replace function public.record_axiom_lesson_result(
  p_user_id uuid,
  p_course_slug text,
  p_unit_number integer,
  p_lesson_number integer,
  p_difficulty text,
  p_correct_answers integer,
  p_total_questions integer,
  p_duration_seconds integer
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_existing boolean;
  v_xp integer;
  v_hearts integer;
  v_heart_updated_at timestamptz;
  v_award integer;
  v_perfect boolean;
begin
  if p_user_id is null
    or p_course_slug not in ('hosa-biotechnology','hosa-biomedical-debate','deca-ftdm')
    or p_unit_number < 1 or p_unit_number > 5
    or p_lesson_number < 1 or p_lesson_number > 10
    or p_difficulty not in ('easy','medium','hard','expert')
    or p_total_questions <> 10
    or p_correct_answers < 0 or p_correct_answers > p_total_questions
    or p_duration_seconds < 0 then
    raise exception 'Invalid lesson result payload';
  end if;

  select exists(
    select 1 from public.axiom_lesson_results
    where user_id = p_user_id and course_slug = p_course_slug
      and unit_number = p_unit_number and lesson_number = p_lesson_number
  ) into v_existing;

  v_perfect := p_correct_answers = p_total_questions;
  v_award := case when v_existing then 0 else p_correct_answers * 10 + case when v_perfect then 20 else 0 end end;

  insert into public.axiom_lesson_results(
    user_id, course_slug, unit_number, lesson_number, difficulty,
    correct_answers, total_questions, duration_seconds, xp_earned, completed_at
  ) values (
    p_user_id, p_course_slug, p_unit_number, p_lesson_number, p_difficulty,
    p_correct_answers, p_total_questions, p_duration_seconds, v_award, now()
  )
  on conflict (user_id, course_slug, unit_number, lesson_number) do nothing;

  insert into public.axiom_user_progress(user_id, xp, hearts, heart_updated_at, updated_at)
  values (p_user_id, 0, 5, now(), now())
  on conflict (user_id) do nothing;

  select xp, hearts, heart_updated_at into v_xp, v_hearts, v_heart_updated_at
  from public.axiom_user_progress where user_id = p_user_id for update;

  if now() - v_heart_updated_at >= interval '24 hours' then
    v_hearts := 5;
    v_heart_updated_at := now();
  end if;

  v_xp := v_xp + v_award;
  if not v_existing then
    v_hearts := greatest(0, v_hearts - (p_total_questions - p_correct_answers));
    if v_perfect then
      v_hearts := least(5, v_hearts + 1);
    end if;
    if p_correct_answers < p_total_questions or v_perfect then
      v_heart_updated_at := now();
    end if;
  end if;

  update public.axiom_user_progress
  set xp = v_xp, hearts = v_hearts, heart_updated_at = v_heart_updated_at, updated_at = now()
  where user_id = p_user_id;

  return jsonb_build_object('xp_awarded', v_award, 'xp_total', v_xp, 'hearts', v_hearts, 'perfect', v_perfect, 'first_completion', not v_existing);
end;
$$;

revoke all on function public.record_axiom_lesson_result(uuid,text,integer,integer,text,integer,integer,integer) from public, anon, authenticated;
grant execute on function public.record_axiom_lesson_result(uuid,text,integer,integer,text,integer,integer,integer) to service_role;


create or replace function public.get_axiom_user_progress(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.axiom_user_progress%rowtype;
begin
  if p_user_id is null then
    raise exception 'Invalid user';
  end if;
  insert into public.axiom_user_progress(user_id,xp,hearts,heart_updated_at,updated_at)
  values(p_user_id,0,5,now(),now())
  on conflict(user_id) do nothing;
  select * into v_row from public.axiom_user_progress where user_id=p_user_id for update;
  if now()-v_row.heart_updated_at >= interval '24 hours' and v_row.hearts < 5 then
    update public.axiom_user_progress set hearts=5,heart_updated_at=now(),updated_at=now()
      where user_id=p_user_id returning * into v_row;
  end if;
  return jsonb_build_object('xp',v_row.xp,'hearts',v_row.hearts,'heart_updated_at',v_row.heart_updated_at,'updated_at',v_row.updated_at);
end;
$$;
revoke all on function public.get_axiom_user_progress(uuid) from public, anon, authenticated;
grant execute on function public.get_axiom_user_progress(uuid) to service_role;

commit;
