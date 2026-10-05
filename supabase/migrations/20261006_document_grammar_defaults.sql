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
