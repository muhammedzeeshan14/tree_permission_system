-- Run once in Supabase SQL Editor before distributing the updated app.
-- Does not renumber/delete applications, history or files.
begin;
lock table public.applications in share row exclusive mode;

create table if not exists public.application_office_number_registry (
  office_number text primary key,
  application_id bigint not null
);
alter table public.application_office_number_registry enable row level security;
revoke all on public.application_office_number_registry from anon, authenticated;

-- Existing duplicates remain untouched, but their numbers are never reused.
insert into public.application_office_number_registry(office_number, application_id)
select btrim("officeNumber"), min(id) from public.applications
where nullif(btrim("officeNumber"), '') is not null
group by btrim("officeNumber")
on conflict (office_number) do nothing;

create or replace function public.guard_application_office_number()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if TG_OP = 'UPDATE' then
    if NEW."officeNumber" is not distinct from OLD."officeNumber" then
      return NEW;
    end if;
  end if;
  if nullif(btrim(NEW."officeNumber"), '') is null then
    raise exception 'Application office number is required' using errcode = '23514';
  end if;
  NEW."officeNumber" := btrim(NEW."officeNumber");
  -- The primary key provides concurrency protection even for old clients.
  insert into public.application_office_number_registry(office_number, application_id)
  values (NEW."officeNumber", NEW.id);
  return NEW;
end;
$$;
revoke all on function public.guard_application_office_number() from public;
drop trigger if exists application_office_number_guard on public.applications;
create trigger application_office_number_guard
before insert or update of "officeNumber" on public.applications
for each row execute function public.guard_application_office_number();

insert into public.office_number_counter(id, last_number)
select 1, coalesce(max(substring("officeNumber" from '/([0-9]+)$')::integer), 0)
from public.applications
on conflict (id) do update set last_number = greatest(
  public.office_number_counter.last_number, excluded.last_number);
-- Reserve in one database transaction even when counter-table RLS is closed.
-- Callers can only advance the sequence, not read/reset arbitrary rows.
create or replace function public.reserve_tpms_office_number()
returns integer language plpgsql security definer set search_path = public, pg_temp
as $$
declare reserved integer;
begin
  insert into public.office_number_counter(id, last_number)
  values (1, 0) on conflict (id) do nothing;
  update public.office_number_counter
  set last_number = greatest(last_number, coalesce((
    select max(substring("officeNumber" from '/([0-9]+)$')::integer)
    from public.applications
  ), 0)) + 1
  where id = 1 returning last_number into reserved;
  return reserved;
end;
$$;
revoke all on function public.reserve_tpms_office_number() from public;
grant execute on function public.reserve_tpms_office_number() to anon, authenticated;
commit;

-- Read-only report for subsequent repair. Do not merge by office number.
select "officeNumber", count(*) as application_count, array_agg(id order by id) as application_ids
from public.applications group by "officeNumber" having count(*) > 1;
