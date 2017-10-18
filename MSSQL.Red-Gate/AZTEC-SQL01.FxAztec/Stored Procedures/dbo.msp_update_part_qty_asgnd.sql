SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_update_part_qty_asgnd] 
( @part varchar (25) ) 
as
---------------------------------------------------------------------------------------
-- 	This procedure re assigns the quantity assigned ( po qty or wo qty ) to the 
--	master prod sched table for the part number supplied. 
--
--	Arguments:	@part	mandatory
--
--	Modifications:	15 JUN 1999, Mamatha Bettagere
--
--	Returns:	1	success
--
--	Process:
--	1. Update qty_assigned = 0 for all rows for that part in mps table
--	2. Get active po qty or wo qty for that part number 
--	3. Get all mps rows for that part order by due date
--	4. Assign quantities in due date order  through all rows
---------------------------------------------------------------------------------------

declare	@part_assign			varchar(25),
	@due_date                       datetime,
	@due	                        datetime,
	@order_no                       numeric(8,0),
	@row_id                         int,
	@origin                         numeric(8,0),
	@source                         int,
	@plant                          varchar(10),
	@qnty				numeric(20,6),
	@assign_qty			numeric(20,6),
	@id				numeric(12,0)

create table #mps_assign (
	part				varchar(25),
	due				datetime,
	source				int,
	origin				numeric(8,0),
	qnty				numeric(20,6),
	id				numeric(12,0))

	begin transaction

--	1. Update qty_assigned = 0 for all rows for that part in mps table
	update	master_prod_sched 
	set	qty_assigned = 0
	where	part = @part

--	2. Get active po qty or wo qty for that part number 
	select	@assign_qty = sum ( standard_qty )
	from	po_detail
	where	part_number = @part and
		status <> 'C'

--	select	@assign_qty_wo = sum(wod.qty_required)
--	from	workorder_detail wod
--	where	wod.part = @part
	
	select	@assign_qty = isnull(@assign_qty,0) + isnull(sum(wod.qty_required - wod.qty_completed),0)
	from	workorder_detail wod
	where	wod.part = @part
	
--	3. Get all mps rows for that part order by due date
	insert	#mps_assign (part, due, source, origin, qnty, id)
	select	part, due, source, origin, qnty, id
	from	master_prod_sched
	where	part = @part
	order by due

	set rowcount 1

 	select 	@due = due, 
	       	@source = source, 
	       	@origin = origin, 
		@qnty = qnty,
		@id	= id
	from	#mps_assign

--	4. Assign quantities in due date order  through all rows

	while ( @@rowcount > 0 )  and ( @assign_qty > 0 )
	begin
		
		set rowcount 0
	
		if @assign_qty > @qnty	
		begin
			update	master_prod_sched
			set	qty_assigned = @qnty
			where	part = @part and
				source = @source and
				origin = @origin and
				due = @due and
				id = @id
		
			select	@assign_qty = @assign_qty - @qnty
		end
		else
		begin
			update	master_prod_sched
			set	qty_assigned = @assign_qty
			where	part = @part and 
				source = @source and
				origin = @origin and
				due = @due and
				id = @id
	
			select	@assign_qty = 0
		end				
	
		set rowcount 1
	
		delete  
		from	#mps_assign
		where	part = @part and
			source = @source and
			origin = @origin and
			due = @due and
			id = @id
	
		set rowcount 1
	
		select	@due = due,		
			@source = source,
			@origin = origin,
			@qnty = qnty,
			@id   = id
		from	#mps_assign
			
	end

	commit transaction					
	
--	select 1

	set rowcount 0
GO
