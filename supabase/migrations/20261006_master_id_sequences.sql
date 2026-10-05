-- Repair automatic IDs after imported explicit master IDs; preserve every row.
begin;
do $$
declare
  t text; seq text; largest bigint; current_value bigint;
begin
  foreach t in array array['section_master','beat_master','master_data','pole_rate_master','application_type_master','permission_type_master','application_type_permission_mapping','forwarded_source_master','revenue_opinion_master','inspection_defer_reason_master','officer_directory'] loop
    seq := pg_get_serial_sequence('public.' || t, 'id');
    if seq is not null then
      execute format('lock table public.%I in access exclusive mode', t);
      execute format('select coalesce(max(id),0) from public.%I',t) into largest;
      execute format('select last_value from %s',seq) into current_value;
      perform setval(seq::regclass,greatest(largest,current_value,1),true);
    end if;
  end loop;
end $$;
commit;
