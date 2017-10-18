SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_recalc_tasks]
(	@machine_no	varchar (10) = null )
---------------------------------------------------------------
--	Purpose:
--
--	This procedure recalculates the runtimes and begin and
--	end times for the tasks on a single machine (pass
--	argument) or all machines (no argument).
--
--	Arguments:
--
--	MachineNO	Optional.
--
--	History:
--
--	19 Nov 1999	Eric Stimpson	Created.
--	07 Jan 2000	Harish Gubbi	Moved the Initialization of start date inside the loop & changed the statement too
--	05 May 2000	Harish Gubbi	Moved the wocursor declaration & deallocation with in the loop, from sql7 POV
--	07 Apr 2002	Harish Gubbi	Included a isnull function on the runtime calculation, as that was causing not to show up in pb
--
--	Process:
--
--	I.	Declarations.
--		A.	Declare variables.
--		B.	Declare cursor.
--		C.	Create temporary storage for machine schedule.
--	II.	Recalculate machines.
--		A.	Open list of machines.
--		B.	Get first machine [only machine if machine was passed].
--		C.	Loop while more machines.
--			1.	Initialize start date, 
--			2.	Prepare work orders.
--				a.	Recalculate balance.
--				b.	Negate sequence.
--			3.	Initialize variables.
--				a.	Initialize the sequence, accumulative runtime, wo start and wo start offset.
--				b.	Initialize temporary machine schedule.
--				c.	Initialize temporary w(tx).  [accumulative work at time x]
--			4.	Recalculate work orders.
--				 .	Declare cursor.
--				a.	Open list of work orders.
--				b.	Get first work order.
--				c.	Loop while more work orders.
--					1)	Set sequence, start date and time, and runtime for this work order.
--					2)	Calculate end_dt for this work order, wo start.
--					3)	Increment sequence.
--					4)	Get next work order.
--				d.	Close work order list.
--				 .	Deallocate cursor
--			5.	Get next machine
--		D.	Close machine list.
---------------------------------------------------------------
as

begin transaction
--	I.	Declarations.
--		A.	Declare variables.
declare	@resource_name	varchar (10),
	@sequence	integer,
	@start		datetime,
	@workorder	varchar (10),
	@wostart	datetime,
	@wostartoffset	real,
	@runtime	real,
	@accumruntime	real

--		B.	Declare cursor.
declare	resourcecursor cursor for
select distinct work_order.machine_no
from	work_order
	join machine on work_order.machine_no = machine.machine_no
where	work_order.machine_no = IsNull ( @machine_no, work_order.machine_no )

/*
declare wocursor cursor for
select	work_order
from	work_order
where	machine_no = @resource_name
order by sequence desc, work_order
*/

--		C.	Create temporary storage for machine schedule.
create table #schedule
(	begin_dt	datetime,
	runtime		real )

create table #workattimex
(	timex		real,
	accumwork	real )

--	II.	Recalculate machines.
--		A.	Open list of machines.
open resourcecursor

--		B.	Get first machine [only machine if machine was passed].
fetch	resourcecursor
into	@resource_name

--		C.	Loop while more machines.
while ( @@fetch_status = 0 )
begin -- (1B)
--			1.	Initialize start date.
	select	@start = isnull ((select	Getdate()
				from	shop_floor_calendar
				where	machine = @resource_name and
					Getdate() between begin_datetime and end_datetime),
				(select	isnull( min ( begin_datetime ), GetDate() ) 
				from	shop_floor_calendar
				where	machine = @resource_name and
				begin_datetime >= Getdate()) )

--			2.	Prepare work orders.
--				a.	Recalculate balance.
	update	workorder_detail
	set	balance = qty_required - qty_completed
	where	balance <> qty_required - qty_completed and
		workorder in
		(	select	work_order
			from	work_order
			where	machine_no = @resource_name )
	
--				b.	Negate sequence.
	update	work_order
	set	sequence = -sequence
	where	sequence < 0 and
		machine_no = @resource_name
	
	update	work_order
	set	sequence = -sequence
	where	machine_no = @resource_name
	
--			3.	Initialize variables.
--				a.	Initialize the sequence, accumulative runtime, wo start and wo start offset.
	select	@sequence = 1,
		@wostartoffset = 0,
		@accumruntime = 0,
		@wostart = @start
	
--				b.	Initialize temporary machine schedule.
	delete	#schedule
	
	insert	#schedule
	select	begin_datetime,
		Convert ( real, DateDiff ( minute, begin_datetime, end_datetime ) ) / 60
	from	shop_floor_calendar
	where	machine = @resource_name and
		begin_datetime >= @start
	
	insert	#schedule
	select	@start,
		Convert ( real, DateDiff ( minute, @start, end_datetime ) / 60 )
	from	shop_floor_calendar
	where	machine = @resource_name and
		@start between begin_datetime and end_datetime
	
	insert	#schedule
	select	@start,
		0
--				c.	Initialize temporary w(tx).  [accumulative work at time x]
	delete	#workattimex
	
	insert	#workattimex
	select	Convert ( real, DateDiff ( minute,
			(	select	min ( trs1.begin_dt )
				from	#schedule trs1 ), begin_dt ) ) / 60,
		IsNull (
			(	select	sum ( runtime )
				from	#schedule trs1
				where	trs1.begin_dt < trs.begin_dt ), 0 )
	from	#schedule trs

--	declare the cursor 		
	declare wocursor cursor for
	select	work_order
	from	work_order
	where	machine_no = @resource_name
	order by sequence desc, work_order
	
--			4.	Recalculate work orders.
--				a.	Open list of work orders.
	open wocursor
	
--				b.	Get first work order.
	fetch	wocursor
	into	@workorder
	
--				c.	Loop while more work orders.
	while ( @@fetch_status = 0 )
	begin -- (2B)
	
--					1)	Set sequence, start date and time, and runtime for this work order.
		update	work_order
		set	sequence = @sequence,
			start_date = @wostart,
			start_time = @wostart,
			runtime =
			(	select	Max ( isnull(balance / IsNull ( pm.parts_per_hour, pmp.parts_per_hour ),0) +
					(	case	when IsNull ( include_setuptime, 'N' ) = 'Y' then IsNull ( IsNull ( pm.setup_time, pmp.setup_time ), 0 )
							else 0
						end ) )
				from	workorder_detail wod
					left outer join part_machine pm on wod.part = pm.part and
						pm.machine = @resource_name
					left outer join part_machine pmp on wod.part = pmp.part and
						pmp.sequence = 1
					cross join parameters
				where	workorder = @workorder )
		from	work_order
		where	work_order = @workorder
		
--					2)	Calculate end_dt for this work order, wo start.
		select	@runtime = Convert ( real, runtime )
		from	work_order
		where	work_order = @workorder
		
		select	@accumruntime = @accumruntime + @runtime
		
		delete	#workattimex
		where	accumwork <
			(	select	max ( accumwork )
				from	#workattimex
				where	accumwork < @accumruntime )
		
		select	@wostartoffset = timex + @accumruntime - accumwork
		from	#workattimex
		where	accumwork =
			(	select	max ( accumwork )
				from	#workattimex
				where	accumwork < @accumruntime )
		
		select	@wostart = DateAdd ( minute, @wostartoffset * 60, @start )
		
		update	work_order
		set	end_date = @wostart,
			end_time = @wostart 
		where	work_order = @workorder
		
--					3)	Increment sequence.
		select	@sequence = @sequence + 1
	
--					4)	Get next work order.
		fetch	wocursor
		into	@workorder
	end -- (2B)
	
--				d.	Close work order list.
	close	wocursor
	deallocate wocursor	
--			5.	Get next machine
	fetch	resourcecursor
	into	@resource_name
end -- (1B)

--		D.	Close machine list.
close	resourcecursor

deallocate resourcecursor
commit transaction
GO
