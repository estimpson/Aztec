/*	Set part-machine for buckets that have in line assembly.*/
update
	pm
set
	machine = '3'
from
	dbo.part_machine pm
where
	part like '12[0-9][0-9]%[12][09][A-Z,-,0-9]%'
	and machine not in ('3', '4')

update
	pm
set
	machine = '4'
from
	dbo.part_machine pm
where
	part like '12[0-9][0-9]%[12][1][A-Z,-,0-9]%'
	and machine not in ('3', '4')

/*	Fill in part-machine for colors. */
insert
	part_machine
select
	part = left(pm.part, len(pm.part) - 1) + mclColorBuckets.ColorCode
,   pm.machine
,   pm.sequence
,   pm.mfg_lot_size
,   pm.process_id
,   pm.parts_per_cycle
,   pm.parts_per_hour
,   pm.cycle_unit
,   pm.cycle_time
,   pm.overlap_type
,   pm.overlap_time
,   pm.labor_code
,   pm.activity
,   pm.setup_time
,   pm.crew_size
from
	part_machine pm
	join custom.MoldingColorLetdown mclColorBuckets
		on mclColorBuckets.MoldApplication = 'Bucket'
		and mclColorBuckets.ColorCode != 'B'
	left join dbo.part_machine pmYa
		on pmYa.part = left(pm.part, len(pm.part) - 1) + mclColorBuckets.ColorCode
		and pmYa.sequence = pm.sequence
where
	pm.part like '12[0][0]%[12][019][A-Z,-,0-9]%B'
	and pmYa.part is null

insert
	part_machine
select
	part = left(pm.part, len(pm.part) - 1) + mclColorBuckets.ColorCode
,   pm.machine
,   pm.sequence
,   pm.mfg_lot_size
,   pm.process_id
,   pm.parts_per_cycle
,   pm.parts_per_hour
,   pm.cycle_unit
,   pm.cycle_time
,   pm.overlap_type
,   pm.overlap_time
,   pm.labor_code
,   pm.activity
,   pm.setup_time
,   pm.crew_size
from
	part_machine pm
	join custom.MoldingColorLetdown mclColorBuckets
		on mclColorBuckets.MoldApplication = 'Bucket'
		and mclColorBuckets.ColorCode != 'B'
	join dbo.part p
		on p.part = left(pm.part, len(pm.part) - 1) + mclColorBuckets.ColorCode
	left join dbo.part_machine pmYa
		on pmYa.part = left(pm.part, len(pm.part) - 1) + mclColorBuckets.ColorCode
		and pmYa.sequence = pm.sequence
where
	pm.part like '12[0-9][0-9]%[12][019][A-Z,-,0-9]%'
	and pmYa.part is null

insert
	dbo.part_machine
select
	p.part
,   min(pm.machine)
,   min(pm.sequence)
,   min(pm.mfg_lot_size)
,   min(pm.process_id)
,   min(pm.parts_per_cycle)
,   min(pm.parts_per_hour)
,   min(pm.cycle_unit)
,   min(pm.cycle_time)
,   min(pm.overlap_type)
,   min(pm.overlap_time)
,   min(pm.labor_code)
,   min(pm.activity)
,   min(pm.setup_time)
,   min(pm.crew_size)
from
	dbo.part_machine pm
	join dbo.part p
		on p.part like left(pm.part, 6) + '%' 
	left join dbo.part_machine pm2
		on pm2.part = p.part
where
	p.part like '12[0-9][0-9]%[12][019][A-Z,-,0-9]%'
	and p.name like '%SHELL%'
	and pm2.part is null
group by
	p.part

select
	p.part
,	p.name
,	(	select machine from part_machine where part = p.part)
,	(	select dbo.part_machine.parts_per_hour from part_machine where part = p.part)
from
	dbo.part p
where
	p.part like '12[0-9][0-9]%[12][019][A-Z,-,0-9]%'
	and p.name like '%SHELL%'
