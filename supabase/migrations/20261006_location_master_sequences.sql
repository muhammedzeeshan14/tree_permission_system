-- Advance location-master ID sequences after explicit-ID imports.
-- Preserves existing records and never moves a sequence backwards.
begin;
lock table public.section_master, public.beat_master in access exclusive mode;
do $$
declare
  table_name text;
  sequence_name text;
  highest_id bigint;
  current_value bigint;
begin
  foreach table_name in array array['section_master', 'beat_master'] loop
    sequence_name := pg_get_serial_sequence('public.' || table_name, 'id');
    if sequence_name is null then
      raise exception 'No automatic ID sequence configured for %', table_name;
    end if;
    execute format('select coalesce(max(id), 0) from public.%I', table_name) into highest_id;
    execute format('select last_value from %s', sequence_name) into current_value;
    perform setval(sequence_name::regclass, greatest(highest_id, current_value, 1), true);
  end loop;
end $$;
commit;
