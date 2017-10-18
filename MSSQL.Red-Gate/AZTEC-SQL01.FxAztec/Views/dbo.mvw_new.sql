SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[mvw_new] (	
	type,   
	part,   
	due,   
	qnty,   
	source,   
	origin,   
	machine,   
	run_time,   
	std_start_date,   
	endgap_start_date,
	startgap_start_date,
	setup,   
	process,
	id,   
	week_no,
	plant,
	eruntime,
	flag)
as
select	part.class type,
	bom.part,
	mps.dead_start due,
	(	case when bom.type = 'T'
			then bom.std_qty
			else mps.qnty * bom.std_qty
		end ) extended_qty,
	mps.source,
	mps.origin,
	IsNull ( part_machine.machine, '' ),
	IsNull ( (	case	when bom.type = 'T' then bom.std_qty
				else mps.qnty * bom.std_qty
			end ) / part_machine.parts_per_hour + (
			case	when parameters.include_setuptime = 'Y' then isnull(part_machine.setup_time,0)
				else 0
			end ), 0 ) runtime,
	IsNull ( dateadd ( mi, - 60 * (( 24.00 / parameters.workhours_in_day ) * 
		((case	when bom.type = 'T' then bom.std_qty
			else mps.qnty * bom.std_qty
		end ) / part_machine.parts_per_hour + 
		(case	when parameters.include_setuptime = 'Y' then isnull(part_machine.setup_time,0)
		 	else 0
		end ))), mps.dead_start ), mps.dead_start ) std_start_date,
	
	IsNull ( dateadd ( mi, - 60 * (( 24.00 / parameters.workhours_in_day ) * 
		((case	when bom.type = 'T' then bom.std_qty
			else mps.qnty * bom.std_qty
		end ) / part_machine.parts_per_hour + 
		(case	when parameters.include_setuptime = 'Y' then isnull(part_machine.setup_time,0)
		 	else 0
		end ) +
		(case	when part_machine.overlap_type = 'S' then ( part_inventory.standard_pack / part_machine.parts_per_hour ) 
			when part_machine.overlap_type = 'T' then part_machine.overlap_time 
		end ))), mps.due ), mps.dead_start ) endgap_start_date,
	
	IsNull ( dateadd ( mi, - 60 * (( 24.00 / parameters.workhours_in_day ) * 
		((case	when parameters.include_setuptime = 'Y' then isnull(part_machine.setup_time,0)
		 	else 0
		end ) +
		(case	when part_machine.overlap_type = 'S' then ( part_inventory.standard_pack / part_machine.parts_per_hour ) 
			when part_machine.overlap_type = 'T' then part_machine.overlap_time
		end ))), mps.dead_start ), convert( datetime, '1900-01-01' ) ) startgap_start_date,
	
	IsNull ( part_machine.setup_time, 0 ),
	part_machine.process_id,
	mps.id,
	datediff ( wk, parameters.fiscal_year_begin, mps.dead_start ),
	mps.plant,
	(60 * (( 24.00 / parameters.workhours_in_day ) * 
		((case	when bom.type = 'T' then bom.std_qty
			else mps.qnty * bom.std_qty
		end ) / part_machine.parts_per_hour + 
		(case	when parameters.include_setuptime = 'Y' then isnull(part_machine.setup_time,0)
		 	else 0
		end )))) eruntime,
	mvw_demand.flag
from	master_prod_sched mps
	join mvw_demand on mps.origin = mvw_demand.first_key and
	mps.source = mvw_demand.second_key
	join mvw_billofmaterial bom on mps.part = bom.parent_part
	join part on bom.part = part.part
	join part_inventory part_inventory on mps.part = part_inventory.part			
	left outer join part_machine on bom.part = part_machine.part and
		part_machine.sequence = 1
	cross join parameters
GO
