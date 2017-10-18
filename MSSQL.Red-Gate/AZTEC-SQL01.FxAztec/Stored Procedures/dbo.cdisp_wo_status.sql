SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[cdisp_wo_status] ( @qty_comp_percent integer = null)
as
begin
	create table #wo_bom	( 
			work_order	varchar(10),
			due_date	datetime,
			machine_no	varchar(10),
			sequence	integer,
			start_date	datetime,
			end_date	datetime,
			wod_part	varchar(25),
			bom_part	varchar(25),
			qty_required	numeric(20,6),
			qty_completed	numeric(20,6),
			bom_std_qty	numeric(20,6),
			assumed_issue_qty numeric(20,6),
			parts_per_hour	numeric(20,6),
			crew_size	integer)
			
	create table	#sf_labor_hours( 
				work_order	varchar(10),
				part		varchar(25),
				labor		numeric(20,6))

	create table	#wo_at	( 
				work_order	varchar(10),
				at_part		varchar(25),
				at_std_qty	numeric(20,6))
				
	if isnull(@qty_comp_percent,0) = 0 
		select @qty_comp_percent = 0 

	Insert	#wo_bom
	select 	wo.work_order, 
		wo.due_date, 
		machine_no, 
		wo.sequence, 
		wo.start_date, 
		wo.end_date, 
		wod.part, 
		bom.part, 
		wod.qty_required, 
		wod.qty_completed,
		bom.std_qty, 
		(wod.qty_completed*bom.std_qty) as assumed_issue_qty,
		pm.parts_per_hour,
		pm.crew_size
	from	work_order 	wo
		join workorder_detail wod on wod.workorder = wo.work_order
		join bill_of_material bom on bom.parent_part = wod.part
		join part_machine pm on pm.part = wod.part and pm.machine = wo.machine_no
	where	(wod.qty_completed/wod.qty_required)*100 >= @qty_comp_percent
	order by wo.work_order,
		wo.sequence,
		wod.part
	
	Insert	#sf_labor_hours
	select	work_order,
		part,
		sum(labor_hours)
	from	shop_floor_time_log
	where	work_order in (select distinct work_order from #wo_bom)
	group by work_order, part
	
			
	insert	#wo_at
	Select	at.workorder,
		at.part,
		sum(at.std_quantity)
	from	audit_trail	at
	where	at.type in ('M', 'N') and
		at.workorder in (Select distinct work_order from #wo_bom)
	group by at.workorder,
		at.part
	
	Select	sflh.work_order,
		sflh.part,
		sflh.labor,
		wobo.work_order,
		wobo.due_date,
		wobo.machine_no,
		wobo.sequence,
		wobo.start_date,
		wobo.end_date,
		wobo.wod_part,
		wobo.bom_part,
		wobo.qty_required,
		wobo.qty_completed,
		wobo.bom_std_qty,
		wobo.assumed_issue_qty,
		wobo.parts_per_hour,
		wobo.crew_size,
		woat.work_order,
		woat.at_part,
		woat.at_std_qty,
		prm.company_name, 
		prm.company_logo
	from	#wo_bom wobo 
		join #wo_at  woat on woat.work_order = wobo.work_order and  woat.at_part = wobo.bom_part
		left outer join #sf_labor_hours sflh on sflh.work_order = wobo.work_order and sflh.part = wobo.wod_part
		cross join parameters prm
end
GO
