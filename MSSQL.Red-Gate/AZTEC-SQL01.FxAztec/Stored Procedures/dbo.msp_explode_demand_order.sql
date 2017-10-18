SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure	[dbo].[msp_explode_demand_order] (
	@firstkey numeric (8,0),
	@secondkey integer )
as
--------------------------------------------------------------------------------------
--	Msp_explode_demand_order
--
--	Parameters :	@firstkey
--
--	Process :
--	
--	1.	Delete MPS
--	2.	Write the current set of releases to MPS
--	3.	Loop on @current_level
--	4.	Insert children of @current_level to MPS
--	5. 	Call msp_assign_quantity
--
--	Development Team - 07/20/1999 
--	Development Team - 08/26/1999	Modified update order_detail statement for performance.
--	Development Team - 09/15/1999	Included paranthesis to compute dead_start correctly
--	Development Team - 01/07/1999	Changed bill_of_material view to mvw_billofmaterial to suppress substitute_parts
--	GPH		 - 04/04/2000	Included overlap time as part of the dropdead date computation & part_inventory join
--					to get the standard pack qty
--------------------------------------------------------------------------------------
--	Declarations

declare	@current_level	integer,
	@part varchar(25)

--	Initialize
select	@current_level = 1

begin	transaction -- (1t)

--	1.	Delete MPS
delete	master_prod_sched
where	master_prod_sched.origin = @firstkey and
	master_prod_sched.source = @secondkey

--	2.	Write the current set of releases to MPS
insert	master_prod_sched (
		type,   
		part,   
		due,   
		qnty,   
		source,   
		origin,   
		machine,   
		run_time,   
		dead_start,   
		job,   
		setup,   
		status,   
		process,   
		qty_assigned,   
		due_time,   
		start_time,   
		id,   
		parent_id,   
		week_no,
		plant )
select	part.class,
	mvw_demand.part,
	mvw_demand.due_dt,
	mvw_demand.std_qty,
	mvw_demand.second_key,
	mvw_demand.first_key,
	IsNull ( part_machine.machine, '' ),
	IsNull ( mvw_demand.std_qty / part_machine.parts_per_hour + (
		case	when parameters.include_setuptime = 'Y' then part_machine.setup_time
			else 0
		end ), 0 ) runtime,
	IsNull ( dateadd ( mi, - 60 * (( 24.00 / parameters.workhours_in_day ) * (mvw_demand.std_qty / part_machine.parts_per_hour +
		(case	when parameters.include_setuptime = 'Y' then part_machine.setup_time
		 	else 0
		end ) -
		isnull((case	when part_machine.overlap_type = 'S' then isnull( ( part_inventory.standard_pack / part_machine.parts_per_hour ),0) 
			when part_machine.overlap_type = 'T' then isnull( part_machine.overlap_time, 0 ) 
		 	else 0
		end ),0))), mvw_demand.due_dt ), mvw_demand.due_dt ) dropdate_date,
	'' job,
	IsNull ( part_machine.setup_time, 0 ),
	'S' status,
	part_machine.process_id,
	0 qty_assigned,
	mvw_demand.due_dt dropdate_time,
	IsNull ( dateadd ( mi, - 60 * (( 24.00 / convert (decimal, parameters.workhours_in_day ) ) * (mvw_demand.std_qty / part_machine.parts_per_hour + 
		(case	when parameters.include_setuptime = 'Y' then part_machine.setup_time
		 	else 0
		end ) -
		isnull((case	when part_machine.overlap_type = 'S' then isnull( ( part_inventory.standard_pack / part_machine.parts_per_hour ),0) 
			when part_machine.overlap_type = 'T' then isnull( part_machine.overlap_time, 0 ) 
		 	else 0
		end ),0))), mvw_demand.due_dt ), mvw_demand.due_dt ) start_time,
	@current_level id,
	0 parent_id,
	datediff ( wk, parameters.fiscal_year_begin, mvw_demand.due_dt ),
	mvw_demand.plant
from	mvw_demand
	join part on mvw_demand.part = part.part
	join part_inventory part_inventory on mvw_demand.part = part_inventory.part		
	left outer join part_machine on mvw_demand.part = part_machine.part and
		part_machine.sequence = 1
	cross join parameters
where	mvw_demand.first_key = @firstkey and
	mvw_demand.second_key = @secondkey

--	3.	Loop on @current_level
while @@rowcount > 0
begin -- (1B)

	select	@current_level = @current_level + 1

--	4.	Insert children of @current_level to MPS
	insert	master_prod_sched (
			type,   
			part,   
			due,   
			qnty,   
			source,   
			origin,   
			machine,   
			run_time,   
			dead_start,   
			job,   
			setup,   
			status,   
			process,   
			qty_assigned,   
			due_time,   
			start_time,   
			id,   
			parent_id,   
			week_no,
			plant )
	select	type,   
		part, 
		isnull(dateadd ( mi, eruntime, 
			(case	when endgap_start_date < std_start_date or endgap_start_date < startgap_start_date then endgap_start_date 
				when startgap_start_date > std_start_date then startgap_start_date 
				else std_start_date
			end)),mvw_new.due) due,
		qnty,   
		source,   
		origin,   
		machine,   
		run_time,   
		(case	when endgap_start_date < std_start_date or endgap_start_date < startgap_start_date then endgap_start_date 
			when startgap_start_date > std_start_date then startgap_start_date 
			else std_start_date
		end) dead_start,
		'' job,
		setup, 
		'S' status,  
		process,   
		0 qty_assigned,
		isnull(dateadd ( mi, eruntime, 
			(case	when endgap_start_date < std_start_date or endgap_start_date < startgap_start_date then endgap_start_date 
				when startgap_start_date > std_start_date then startgap_start_date 
				else std_start_date
			end)),mvw_new.due) dropdate_time,
		(case	when endgap_start_date < std_start_date or endgap_start_date < startgap_start_date then endgap_start_date 
			when startgap_start_date > std_start_date then startgap_start_date 
			else std_start_date
		end) start_time,
		@current_level id,
		0 parent_id,	
		week_no,
		plant			
	from	mvw_new
	where	mvw_new.id = @current_level - 1 and
		mvw_new.origin = @firstkey and
		mvw_new.source = @secondkey
end -- (1B)

--	call msp_assign_quantity procedure

declare parts cursor for
select  mps.part 
from	master_prod_sched mps
where   mps.origin = @firstkey and
	mps.source = @secondkey
group 	by mps.part

open	parts

fetch parts into @part 

while @@fetch_status = 0 
begin

--	5. 	call msp_assign_quantity
	execute msp_assign_quantity @part

	fetch parts into @part 

end

close parts

deallocate parts 

commit transaction -- ( 1T )
GO
