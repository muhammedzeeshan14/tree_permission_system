begin;
alter table public.applications add column if not exists "deletedPreviousStatus" text;
alter table public.applications add column if not exists "deletedAt" timestamptz;
alter table public.applications add column if not exists "deletedBy" integer;
create or replace function public.tpms_set_application_deleted(p_ids bigint[], p_actor bigint, p_restore boolean default false)
returns integer language plpgsql security definer set search_path = public as $$
declare changed integer;
begin
 if not exists(select 1 from users where id=p_actor and upper(trim(role))='RFO' and "isActive"=1) then
  raise exception 'Only an active RFO can delete or restore applications';
 end if;
 if coalesce(array_length(p_ids,1),0)=0 then return 0; end if;
 if array_length(p_ids,1)>500 then raise exception 'Select at most 500 applications at once'; end if;
 perform set_config('tpms.application_recovery','allowed',true);
 if p_restore then
  update applications set status="deletedPreviousStatus", "deletedPreviousStatus"=null,"deletedAt"=null,"deletedBy"=null
   where id=any(p_ids) and status='Deleted' and "deletedPreviousStatus" is not null;
 else
  update applications set "deletedPreviousStatus"=status,status='Deleted',"deletedAt"=now(),"deletedBy"=p_actor
   where id=any(p_ids) and status is distinct from 'Deleted';
 end if;
 get diagnostics changed = row_count;
 return changed;
end $$;
create or replace function public.tpms_guard_deleted_application() returns trigger language plpgsql as $$
begin
 if old.status='Deleted' and current_setting('tpms.application_recovery',true) is distinct from 'allowed' then
  raise exception 'Application has been deleted by RFO. Refresh your dashboard.';
 end if;
 return new;
end $$;
drop trigger if exists tpms_guard_deleted_application on public.applications;
create trigger tpms_guard_deleted_application before update on public.applications for each row execute function public.tpms_guard_deleted_application();
commit;
select 'Bulk deletion and recovery ready; no applications deleted' as result;
