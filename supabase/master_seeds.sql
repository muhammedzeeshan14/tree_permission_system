-- ============================================================
-- TPMS cloud seed (run ONCE in Supabase SQL Editor)
-- Fills users, sections, beats and all master defaults so every
-- device sees the same masters. Safe to re-run (upserts by id /
-- skips existing master rows).
-- ============================================================

-- ---------- users ----------
insert into public.users
  (id, name, username, password, role, "sectionId", "beatId", "isActive")
values
  (1, 'System Administrator', 'admin', 'admin123', 'RFO', null, null, 1),
  (2, 'Range Forest Officer', 'rfo', '1234', 'RFO', null, null, 1),
  (3, 'Deputy Range Forest Officer', 'drfo', '1234', 'DRFO', 1, null, 1),
  (4, 'Beat Forest Officer', 'bfo1', '1234', 'BFO', 1, 1, 1),
  (5, 'Case Worker', 'caseworker', '1234', 'Case Worker', null, null, 1)
on conflict (id) do nothing;

-- ---------- sections ----------
insert into public.section_master
  (id, "sectionName", "kannadaName", "displayOrder", "isActive")
values
  (1, 'Mysuru Urban', 'ಮೈಸೂರು ನಗರ', 1, 1),
  (2, 'Mysuru Rural', 'ಮೈಸೂರು ಗ್ರಾಮಾಂತರ', 2, 1),
  (3, 'Mysuru South', 'ಮೈಸೂರು ದಕ್ಷಿಣ', 3, 1)
on conflict (id) do nothing;

-- ---------- beats ----------
insert into public.beat_master
  (id, "sectionId", "beatName", "kannadaName", "displayOrder", "isActive")
values
  (1, 1, 'Nazarbad', 'ನಜರಬಾದ್', 1, 1),
  (2, 1, 'Siddarthanagar', 'ಸಿದ್ಧಾರ್ಥನಗರ', 2, 1),
  (3, 2, 'Chamundi', 'ಚಾಮುಂಡಿ', 1, 1),
  (4, 2, 'Yelwala', 'ಯಳವಳ', 2, 1)
on conflict (id) do nothing;

-- ---------- master_data helper ----------
-- (masterType, value, code, parentCode, displayOrder, kannadaName)
-- inserted only when the same type+value is absent.

do $$
declare
  r record;
begin
  for r in
    select * from (values
      ('Section','Section-1','S1','',1,''),
      ('Section','Section-2','S2','',2,''),
      ('Beat','Beat-1','B1','',1,''),
      ('Beat','Beat-2','B2','',2,''),
      ('Problem','Dangerous','','',1,'ಅಪಾಯಕಾರಿ'),
      ('Problem','Dead','','',2,'ಸತ್ತ'),
      ('Problem','Dry','','',3,'ಒಣಗಿದ'),
      ('Recommendation Type','Full Tree','FULL','',1,'ಪೂರ್ಣ ಮರ'),
      ('Recommendation Type','Branches Only','BRANCH','',2,'ಕೊಂಬೆಗಳು ಮಾತ್ರ'),
      ('Recommendation Type','Twigs Only','TWIG','',3,'ಸಣ್ಣ ಕೊಂಬೆಗಳು ಮಾತ್ರ'),
      ('Recommendation Type','Top Portion Above 20 Feet','TOP','',4,'20 ಅಡಿ ಮೇಲಿನ ತುದಿ ಭಾಗ'),
      ('Recommendation Type','Not Recommended','NR','',5,'ಶಿಫಾರಸು ಮಾಡಲಾಗಿಲ್ಲ'),
      ('Recommendation Reason','Dead Tree','DEAD','FULL',1,'ಸತ್ತ ಮರ'),
      ('Recommendation Reason','Diseased Tree','DISEASE','FULL',2,'ರೋಗಪೀಡಿತ ಮರ'),
      ('Recommendation Reason','Dangerous Tree','DANGER','FULL',3,'ಅಪಾಯಕಾರಿ ಮರ'),
      ('Recommendation Reason','Leaning Tree','LEAN','FULL',4,'ವಾಲಿದ ಮರ'),
      ('Recommendation Reason','Electric Line Clearance','LINE','BRANCH',1,'ವಿದ್ಯುತ್ ತಂತಿ ತೆರವು'),
      ('Recommendation Reason','Building Clearance','BUILDING','BRANCH',2,'ಕಟ್ಟಡ ತೆರವು'),
      ('Recommendation Reason','Road Clearance','ROAD','BRANCH',3,'ರಸ್ತೆ ತೆರವು'),
      ('Recommendation Reason','Public Safety','SAFETY','BRANCH',4,'ಸಾರ್ವಜನಿಕ ಸುರಕ್ಷತೆ'),
      ('Recommendation Reason','Routine Pruning','ROUTINE','TWIG',1,'ನಿಯಮಿತ ಕತ್ತರಿಕೆ'),
      ('Recommendation Reason','Nursery Requirement','NURSERY','TWIG',2,'ನರ್ಸರಿ ಅಗತ್ಯ'),
      ('Recommendation Reason','Dry Top','DRYTOP','TOP',1,'ಒಣಗಿದ ತುದಿ'),
      ('Recommendation Reason','Safety Clearance','SAFE','TOP',2,'ಸುರಕ್ಷತಾ ತೆರವು'),
      ('Recommendation Reason','Healthy Tree','HEALTHY','NR',1,'ಆರೋಗ್ಯಕರ ಮರ'),
      ('Recommendation Reason','Heritage Tree','HERITAGE','NR',2,'ಪರಂಪರೆ ಮರ'),
      ('Recommendation Reason','Bird Nest Present','BIRDNEST','NR',3,'ಹಕ್ಕಿ ಗೂಡು ಇದೆ'),
      ('Recommendation Reason','Religious Importance','RELIGIOUS','NR',4,'ಧಾರ್ಮಿಕ ಮಹತ್ವ'),
      ('Recommendation Reason','Others','OTHER','NR',5,'ಇತರೆ'),
      ('Return Reason','Clarification Required','','',1,'ಸ್ಪಷ್ಟೀಕರಣ ಅಗತ್ಯ'),
      ('Return Reason','Documents Missing','','',2,'ದಾಖಲೆಗಳು ಲಭ್ಯವಿಲ್ಲ'),
      ('Inspection Deferred Reason','Applicant Not Available','','',1,'ಅರ್ಜಿದಾರರು ಲಭ್ಯವಿಲ್ಲ'),
      ('Inspection Deferred Reason','Site Not Traceable','','',2,'ಸ್ಥಳ ಪತ್ತೆಯಾಗಿಲ್ಲ'),
      ('Inspection Deferred Reason','Documents Not Available','','',3,'ದಾಖಲೆಗಳು ಲಭ್ಯವಿಲ್ಲ'),
      ('Inspection Deferred Reason','Wrong Location','','',4,'ತಪ್ಪು ಸ್ಥಳ'),
      ('Inspection Deferred Reason','Tree Already Removed','','',5,'ಮರವನ್ನು ಈಗಾಗಲೇ ತೆಗೆದುಹಾಕಲಾಗಿದೆ'),
      ('Inspection Deferred Reason','Others','','',6,'ಇತರೆ'),
      ('Standard Remark','Inspection Completed','','',1,'ಪರಿಶೀಲನೆ ಪೂರ್ಣಗೊಂಡಿದೆ'),
      ('Standard Remark','Verified','','',2,'ಪರಿಶೀಲಿಸಲಾಗಿದೆ'),
      ('Document Type','RTC','','',1,'ಆರ್‌ಟಿಸಿ'),
      ('Document Type','Survey Sketch','','',2,'ಸರ್ವೆ ನಕ್ಷೆ'),
      ('Document Type','Aadhaar','','',3,'ಆಧಾರ್'),
      ('Document Type','Revenue Certificate','','',4,'ಕಂದಾಯ ಪ್ರಮಾಣಪತ್ರ'),
      ('Document Type','Ownership Proof','','',5,'ಮಾಲೀಕತ್ವ ಪುರಾವೆ'),
      ('Document Type','Court Order','','',6,'ನ್ಯಾಯಾಲಯದ ಆದೇಶ'),
      ('Document Type','Other','','',7,'ಇತರೆ'),
      ('Workflow Status','Draft','DRAFT','',1,''),
      ('Workflow Status','Pending BFO','PBFO','',2,''),
      ('Workflow Status','Pending DRFO','PDRFO','',3,''),
      ('Workflow Status','Pending RFO','PRFO','',4,''),
      ('Workflow Status','Returned by DRFO','RDRFO','',5,''),
      ('Workflow Status','Returned by RFO','RRFO','',6,''),
      ('Workflow Status','Approved','APP','',7,''),
      ('Workflow Status','Rejected','REJ','',8,''),
      ('Verification Reason','Application Type Incorrect','APPTYPE01','APPLICATION_TYPE',1,''),
      ('Verification Reason','GPS Location Incorrect','GPS01','GPS',1,''),
      ('Verification Reason','Wrong Tree Details','TREE01','TREE',1,''),
      ('Verification Reason','Wrong Recommendation','TREE02','TREE',2,''),
      ('Verification Reason','Required Photos Missing','PHOTO01','PHOTO',1,''),
      ('Verification Reason','Required Documents Missing','DOC01','DOCUMENT',1,''),
      ('Verification Reason','Deferred Reason Incorrect','DEFER01','DEFERRED',1,''),
      ('Document Master','Tree Enumeration List','ENUM','ALL',1,''),
      ('Document Master','Mahazar','MAHAZAR','ALL',2,''),
      ('Document Master','Covering Letter','COVER','ALL',3,''),
      ('Document Master','Inspection Report','REPORT','ALL',4,''),
      ('Document Template','Enumeration Template','ENUM_V1','ENUM',1,''),
      ('Document Template','Mahazar Template','MAHAZAR_V1','MAHAZAR',2,''),
      ('Document Template','Cover Letter Template','COVER_V1','COVER',3,''),
      ('Document Template','Inspection Report Template','REPORT_V1','REPORT',4,''),
      ('Government Agency','Forest Department','FOREST','',1,'ಅರಣ್ಯ ಇಲಾಖೆ'),
      ('Government Agency','Revenue Department','REVENUE','',2,'ಕಂದಾಯ ಇಲಾಖೆ'),
      ('Government Agency','Public Works Department','PWD','',3,'ಲೋಕೋಪಯೋಗಿ ಇಲಾಖೆ'),
      ('Urban Rural','Urban','URBAN','',1,'ನಗರ'),
      ('Urban Rural','Rural','RURAL','',2,'ಗ್ರಾಮಾಂತರ'),
      ('Urban Rural','Semi-Urban','SEMI','',3,'ಅರೆ ನಗರ'),
      ('Tree Status','Healthy','HEALTHY','',1,'ಆರೋಗ್ಯಕರ'),
      ('Tree Status','Dead','DEAD','',2,'ಸತ್ತ'),
      ('Tree Status','Dangerous','DANGEROUS','',3,'ಅಪಾಯಕಾರಿ'),
      ('Tree Status','Diseased','DISEASED','',4,'ರೋಗಪೀಡಿತ'),
      ('Inspecting Officer Overall Remark','Recommended','RECOMMENDED','',1,'ಶಿಫಾರಸು ಮಾಡಲಾಗಿದೆ'),
      ('Inspecting Officer Overall Remark','Not Recommended','NOT_RECOMMENDED','',2,'ಶಿಫಾರಸು ಮಾಡಲಾಗಿಲ್ಲ'),
      ('Inspecting Officer Overall Remark','Need Re-inspection','REINSPECT','',3,'ಮರು ಪರಿಶೀಲನೆ ಅಗತ್ಯ'),
      ('Mahazar Location','East','EAST','',1,'ಪೂರ್ವ'),
      ('Mahazar Location','West','WEST','',2,'ಪಶ್ಚಿಮ'),
      ('Mahazar Location','North','NORTH','',3,'ಉತ್ತರ'),
      ('Mahazar Location','South','SOUTH','',4,'ದಕ್ಷಿಣ'),
      ('Sandal Destination','Sandalwood Depot, Mysuru','MYSURU_DEPOT','BOTH',1,'ಶ್ರೀಗಂಧ ಡಿಪೋ, ಮೈಸೂರು'),
      ('Sandal Destination','Sandalwood Depot, Bengaluru','BENGALURU_DEPOT','BOTH',2,'ಶ್ರೀಗಂಧ ಡಿಪೋ, ಬೆಂಗಳೂರು'),
      ('Sandal Destination','Sandalwood Depot, Hunsur','HUNSUR_DEPOT','BOTH',3,'ಶ್ರೀಗಂಧ ಡಿಪೋ, ಹುಣಸೂರು')
    ) as v("masterType", value, code, "parentCode", "displayOrder", "kannadaName")
  loop
    if not exists (
      select 1 from public.master_data m
      where m."masterType" = r."masterType" and m.value = r.value
    ) then
      insert into public.master_data
        ("masterType", value, code, "parentCode", "displayOrder",
         remarks, "kannadaName", "isActive")
      values
        (r."masterType", r.value, r.code, r."parentCode",
         r."displayOrder", '', r."kannadaName", 1);
    end if;
  end loop;
end $$;

-- ---------- application types ----------
insert into public.application_type_master
  ("applicationType", "kannadaName", "shortCode", "displayOrder", "isActive")
values
  ('State Government Land', 'ರಾಜ್ಯ ಸರ್ಕಾರದ ಜಾಗ', 'STGL', 1, 1),
  ('Central Government Land', 'ಕೇಂದ್ರ ಸರ್ಕಾರದ ಜಾಗ', 'CGL', 2, 1),
  ('Private Land', 'ಖಾಸಗಿ ಜಾಗ', 'PL', 3, 1),
  ('RTC Entry', 'ಆರ್‌ಟಿಸಿ ನಮೂದು', 'RTC', 4, 1),
  ('MCC', 'ಮೈಸೂರು ಮಹಾನಗರ ಪಾಲಿಕೆ', 'MCC', 5, 1),
  ('Sandal Government', 'ಸರ್ಕಾರಿ ಶ್ರೀಗಂಧ', 'SGL', 6, 1),
  ('Sandal Private', 'ಖಾಸಗಿ ಶ್ರೀಗಂಧ', 'SPL', 7, 1)
on conflict do nothing;

-- ---------- permission types ----------
insert into public.permission_type_master
  ("permissionType", "displayOrder", "isActive")
values
  ('Permission', 1, 1),
  ('Valuation', 2, 1),
  ('Tree Count', 3, 1),
  ('Forward to Tree Officer', 4, 1),
  ('Auction', 5, 1),
  ('Sandal Depot', 6, 1)
on conflict do nothing;

-- ---------- forwarded sources ----------
insert into public.forwarded_source_master
  ("sourceName", "shortCode", "displayOrder", "isActive")
values
  ('DCF Office', 'DCF', 1, 1),
  ('ACF Office', 'ACF', 2, 1),
  ('MCC', 'MCC', 3, 1),
  ('MUDA', 'MUDA', 4, 1),
  ('NHAI', 'NHAI', 5, 1),
  ('BESCOM', 'BESCOM', 6, 1),
  ('KPTCL', 'KPTCL', 7, 1),
  ('PWD', 'PWD', 8, 1),
  ('Gram Panchayat', 'GP', 9, 1),
  ('Taluk Office', 'TALUK', 10, 1),
  ('Deputy Commissioner''s Office', 'DC', 11, 1),
  ('Others', 'OTHER', 12, 1)
on conflict do nothing;

-- ---------- defer reasons ----------
insert into public.inspection_defer_reason_master
  (reason, "displayOrder", "isActive")
values
  ('Applicant Absent', 1, 1),
  ('Heavy Rain', 2, 1),
  ('Site Not Accessible', 3, 1),
  ('Documents Not Available', 4, 1),
  ('Owner Requested Postponement', 5, 1),
  ('Law & Order Situation', 6, 1),
  ('Court Stay', 7, 1),
  ('Other', 8, 1)
on conflict do nothing;

-- ---------- tree officers ----------
insert into public.tree_officer_master (id, code, name)
values (1, 'RFO', 'RFO'), (2, 'ACF', 'ACF'), (3, 'DCF', 'DCF')
on conflict (id) do nothing;

-- ---------- revenue opinions ----------
insert into public.revenue_opinion_master
  ("revenueOpinion", code, "officeName", "officeAddress",
   "kannadaName", "kannadaDesignation", "kannadaOfficeAddress",
   remarks, "displayOrder", "isActive")
values
  ('Private Land', 'PL', 'Tahsildar, Mysuru Taluk',
   'Mini Vidhana Soudha, Nazarbad, Mysuru - 570010',
   'ಖಾಸಗಿ ಜಮೀನು', 'ತಹಶೀಲ್ದಾರ್, ಮೈಸೂರು ತಾಲ್ಲೂಕು',
   'ಮಿನಿ ವಿಧಾನಸೌಧ, ನಜರಬಾದ್, ಮೈಸೂರು - 570010', '', 1, 1),
  ('Government Land', 'GL', 'Tahsildar, Mysuru Taluk',
   'Mini Vidhana Soudha, Nazarbad, Mysuru - 570010',
   'ಸರ್ಕಾರಿ ಜಮೀನು', 'ತಹಶೀಲ್ದಾರ್, ಮೈಸೂರು ತಾಲ್ಲೂಕು',
   'ಮಿನಿ ವಿಧಾನಸೌಧ, ನಜರಬಾದ್, ಮೈಸೂರು - 570010', '', 2, 1),
  ('Deemed Forest', 'DF', 'Deputy Commissioner, Mysuru',
   'Deputy Commissioner''s Office, Mysuru - 570001',
   'ಡೀಮ್ಡ್ ಅರಣ್ಯ', 'ಜಿಲ್ಲಾಧಿಕಾರಿ, ಮೈಸೂರು',
   'ಜಿಲ್ಲಾಧಿಕಾರಿಗಳ ಕಛೇರಿ, ಮೈಸೂರು - 570001', '', 3, 1),
  ('Not Required', 'NR', '', '',
   'ಅಗತ್ಯವಿಲ್ಲ', '', '',
   'Revenue opinion not required.', 4, 1)
on conflict do nothing;

-- ---------- office configuration ----------
insert into public.office_configuration
  ("rangeName", "rangeCode", "officePrefix", "financialYear",
   "rangeOfficeAddress", division, "subDivision")
select 'Mysuru Range', 'MYR', 'MYR', '2026-27',
       'Range Forest Office, Mysuru',
       'Mysuru Division', 'Mysuru Sub Division'
where not exists (select 1 from public.office_configuration);

-- ---------- type → permission mapping ----------
-- application types: 1 STGL, 2 CGL, 3 PL, 4 RTC, 5 MCC, 6 SGL, 7 SPL
-- permission types: 1 Permission, 2 Valuation, 3 Tree Count,
--   4 Forward to Tree Officer, 5 Auction, 6 Sandal Depot
insert into public.application_type_permission_mapping
  ("applicationTypeId", "permissionTypeId")
select mapping.a, mapping.p
from (values (1,1),(2,1),(3,1),(4,3),(5,1),(6,6),(7,2)) as mapping(a,p)
where not exists (
  select 1 from public.application_type_permission_mapping m
  where m."applicationTypeId" = mapping.a
);

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

-- Grammar-safe defaults
-- Preserve historical IDs and custom entries; retire bundled defaults.
begin;
lock table public.master_data in share row exclusive mode;
update public.master_data set "isActive"=0 where (("masterType"='Why Removing' and value in ('Dangerous tree/branch','Self convenience','Development work','Financial benefit')) or ("masterType"='Purpose' and value in ('House Construction','Agriculture','Road Widening','Safety')) or ("masterType"='Structure Type' and value in ('Building','Road','Layout'))) and coalesce(remarks,'') <> 'GRAMMAR_DEFAULT_20261006';
insert into public.master_data ("masterType",value,code,"parentCode","displayOrder","kannadaName",remarks,"isActive")
select d.*, 'GRAMMAR_DEFAULT_20261006', 1 from (values
('Why Removing','Dangerous tree/branch','DANGER','',1,'ಅಪಾಯ ಉಂಟಾಗುತ್ತಿರುವ'),
('Why Removing','Development work','WORKS','',2,'ಅಡಚಣೆ ಉಂಟಾಗುತ್ತಿರುವ'),
('Why Removing','Road widening','WIDEN','',3,'ಅಡಚಣೆ ಉಂಟಾಗುತ್ತಿರುವ'),
('Why Removing','Repair work','REPAIR','',4,'ಅಡಚಣೆ ಉಂಟಾಗುತ್ತಿರುವ'),
('Why Removing','Damage to property','DAMAGE','',5,'ಹಾನಿ ಉಂಟಾಗುತ್ತಿರುವ'),
('Purpose','Safety','GRAMMAR_SAFETY','DANGER',1,'ಸುರಕ್ಷತೆಗೆ'),
('Purpose','Construction','GRAMMAR_CONSTRUCTION','WORKS',2,'ನಿರ್ಮಾಣ ಕಾಮಗಾರಿಗೆ'),
('Purpose','Widening','GRAMMAR_WIDENING','WIDEN',3,'ಅಗಲೀಕರಣ ಕಾಮಗಾರಿಗೆ'),
('Purpose','Repair','GRAMMAR_REPAIR','REPAIR',4,'ದುರಸ್ತಿ ಕಾಮಗಾರಿಗೆ'),
('Purpose','Protection','GRAMMAR_PROTECTION','DAMAGE',5,'ರಕ್ಷಣೆಗೆ'),
('Structure Type','Building','GRAMMAR_BUILDING','',1,'ಕಟ್ಟಡ'),
('Structure Type','Road','GRAMMAR_ROAD','',2,'ರಸ್ತೆ'),
('Structure Type','Drain','GRAMMAR_DRAIN','',3,'ಚರಂಡಿ'),
('Structure Type','Bridge','GRAMMAR_BRIDGE','',4,'ಸೇತುವೆ'),
('Structure Type','Compound wall','GRAMMAR_COMPOUND','',5,'ಕಾಂಪೌಂಡ್ ಗೋಡೆ')
) as d("masterType",value,code,"parentCode","displayOrder","kannadaName")
where not exists (select 1 from public.master_data m where m."masterType"=d."masterType" and m.code=d.code and m.remarks='GRAMMAR_DEFAULT_20261006');
commit;
select "masterType",count(*) as default_entries from public.master_data where remarks='GRAMMAR_DEFAULT_20261006' and "isActive"=1 group by "masterType" order by "masterType";
