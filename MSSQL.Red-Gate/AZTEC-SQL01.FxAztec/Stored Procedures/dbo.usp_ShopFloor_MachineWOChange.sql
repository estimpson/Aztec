SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[usp_ShopFloor_MachineWOChange]
	@WorkOrder varchar(10),
	@Action integer = 0 output,
	@Result integer = null output
as
--------------------------------------------------------------------------------
--	Description:
-- 	This procedure enforces business rules regarding changing work orders on
--	a machine.  Depending on whether the machine automatically changes work
--	orders, prompts before changing, or doesn't change work orders, the
--	action indicated by the Action argument will be taken(only if	current
--	work order is completed).
--
--	|===============|===============|===============|======================|
--	| MachType      | Action IN     | Action OUT    | Description          |
--	|===============|===============|===============|======================|
--	| Auto Next     | Ignored       | 1 (WO Changed)| Because auto next,   |
--	|               |               |               | action in is ignored,|
--	|               |               |               | work order is        |
--	|               |               |               | changed.             |
--	|---------------|---------------|---------------|----------------------|
--	| Prompt        | 0             | 0 (Prompt)    | Action code required.|
--	|---------------|---------------|---------------|----------------------|
--	| Prompt        | 1             | 1 (WO Changed)| Action code given.   |
--	|---------------|---------------|---------------|----------------------|
--	| Don't Prompt  | Ignored       | -1 (No Change)| Work orders not      |
--	|               |               |               | changed.             |
--	|---------------|---------------|---------------|----------------------|
--
--------------------------------------------------------------------------------

--	I.	Declarations.
--		A.	Local variables.
declare
	@Machine varchar(10),
	@MachineType char(1),
	@Sequence integer

--	II.	Validate data.
--		A.	Work order must be valid.
select
	@Machine = machine_no,
	@Sequence = sequence
from
	work_order
where
	work_order = @WorkOrder

if	@@rowcount = 0 begin
	select	@Result = -1
	return	@Result
end

--		B.	Machine must be valid.
select
	@MachineType = IsNull(job_change, 'D')
from
	machine_policy
where
	machine = @Machine

if	@@rowcount = 0 begin
	select	@Result = -2
	return	@Result
end

--	If Work Order is complete...
if	not exists
	(	select
			1
		from
			workorder_detail
		where
			workorder = @WorkOrder
			and
				qty_required > qty_completed
	) begin
--		Set action code according to type of machine and passed action.
	select
		@Action =
		case
			when @MachineType = 'N' then 1
			when @MachineType = 'D' then -1
			else @Action
		end

--		B.	Change work order if action is indicated.
	if	@Action = 1 begin
		insert
			workorder_header_history
		(
			work_order
		,   tool
		,   due_date
		,   cycles_required
		,   cycles_completed
		,   machine_no
		,   process_id
		,   customer_part
		,   setup_time
		,   cycles_hour
		,   standard_pack
		,   sequence
		,   cycle_time
		,   start_date
		,   start_time
		,   end_date
		,   end_time
		,   runtime
		,   employee
		,   type
		,   accum_run_time
		,   cycle_unit
		,   material_shortage
		,   lot_control_activated
		,   plant
		,   order_no
		,   destination
		,   customer
		,   note
		)
		select
			work_order
		,   tool
		,   due_date
		,   cycles_required
		,   cycles_completed
		,   machine_no
		,   process_id
		,   customer_part
		,   setup_time
		,   cycles_hour
		,   standard_pack
		,   sequence
		,   cycle_time
		,   start_date
		,   start_time
		,   end_date
		,   end_time
		,   runtime
		,   employee
		,   type
		,   accum_run_time
		,   cycle_unit
		,   material_shortage
		,   lot_control_activated
		,   plant
		,   order_no
		,   destination
		,   customer
		,   note
		from
			work_order
		where
			work_order = @WorkOrder
		
		insert
			workorder_detail_history
		(
			workorder
		,   part
		,   qty_required
		,   qty_completed
		,   parts_per_cycle
		,   run_time
		,   scrapped
		,   balance
		,   plant
		,   parts_per_hour
		)
		select
			workorder
		,   part
		,   qty_required
		,   qty_completed
		,   parts_per_cycle
		,   run_time
		,   scrapped
		,   balance
		,   plant
		,   parts_per_hour
		from
			workorder_detail
		where
			workorder = @WorkOrder
		
		delete
			workorder_detail
		where
			workorder = @WorkOrder
		
		delete
			work_order
		where
			work_order = @WorkOrder
		
		update
			work_order
		set
			sequence = sequence - 1
		where
			machine_no = @Machine
			and
				sequence > @Sequence
	end
end
else begin
	select	@Action = -1
end

--	IV.	Return.
select	@Result = 0
return	@Result
GO
