SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_wo_creation] 
(@part       varchar(25),
@qty        numeric(20,6),
@due_date   datetime,
@process_id varchar(25),
@machine_no varchar(10),
@setup_time numeric(15,7),
@runtime    numeric(15,7),
@cycle_time int,          
@cycle_unit varchar(15), 
@parts_per_hour numeric(20,6), 
@parts_per_cycle numeric(20,6),
@startdate  datetime,
@enddate    datetime,
@returnvalue integer OUTPUT,
@eworkorder varchar(10),
@rworkorder varchar(10) OUTPUT) as
-------------------------------------------------------------------------------------------------
--	Procedure	msp_wo_creation
--	Purpose		To create manual work orders 
--	Arguments	Couple of them, see the above for list
--
--	Development	Developer	Date	Description
--			GPH		No idea	Created long time back
--			GPH		4/27/01	Included a procedure call at the end of the proc
--			GPH		8/8/02	Included work order as input and output argument
------------------------------------------------------------------------------------------------

begin -- (1b)
	declare	@work_order varchar(10),
		@woorder integer,
		@note varchar(255),
		@qty_tobeassigned numeric(20,6),
		@mps_qnty  numeric(20,6),
		@qty_remain numeric(20,6),
		@part_type char(1),
		@qnty numeric(20,6),
		@due datetime,
		@source integer, 
		@origin integer,
		@id integer,
		@updqty numeric(20,6),
		@totcount integer,
		@tool	varchar(10),
		@wonumber varchar(10),
		@seq integer
	create table #mps_temp 
		(qnty       numeric(20,6) null,
		part       varchar(25) not null,
		due        datetime not null,
		source     integer not null,
		origin     integer null,
		id         integer null )
	begin transaction 
	-- get next work order number from parameters table
	SELECT	@woorder=next_workorder
	FROM	parameters
	SELECT	@work_order=CONVERT(varchar,@woorder)    
	-- get the tool from part_machine_tool    
	SELECt	@tool = tool
	from	part_machine_tool
	where	part = @part

	SELECT	@note='Manual work order',
		@returnvalue = 0 

	SET rowcount 0 
	-- insert data into work order header                  
	INSERT 
	INTO	work_order 
		(work_order,machine_no,sequence,due_date,process_id,setup_time, 
		cycle_time,start_date,start_time,end_date,end_time,runtime,cycle_unit,
		note,order_no,destination,customer,tool)    
	VALUES	(@work_order,@machine_no,@woorder,@due_date,@process_id,@setup_time,
		@cycle_time,@startdate,@startdate,@enddate,@enddate,@runtime,@cycle_unit,
		@note,0,'','', @tool) 
	if (@@rowcount <= 0)
		select @returnvalue = -1  
	else  
	begin  
	-- insert data into work order detail
	INSERT 
	INTO	workorder_detail
		(workorder,part,qty_required,qty_completed,parts_per_cycle,run_time,
		balance,parts_per_hour) 
	VALUES (@work_order,@part,@qty,0,@parts_per_cycle,@runtime,@qty,
		@parts_per_hour)
	if (@@rowcount <= 0)
		select @returnvalue = -2  
	-- get next work order number
	UPDATE parameters SET next_workorder=@woorder+1
	if (@@rowcount <= 0)
		select @returnvalue = -3  
	end 

	if (@returnvalue = 0)
		execute msp_update_mps_assignedqty @part, @returnvalue 

	if (@returnvalue <> 0)
		rollback transaction
	else
	begin
		commit transaction
		select @rworkorder = @work_order
		--	Added this procedure call, so that, it recalc runtime for that machine 
		--	and re-sequences work orders on that machine
		execute msp_recalc_tasks @machine_no
	end	
		
	set rowcount 0    
end -- (1e)
GO
