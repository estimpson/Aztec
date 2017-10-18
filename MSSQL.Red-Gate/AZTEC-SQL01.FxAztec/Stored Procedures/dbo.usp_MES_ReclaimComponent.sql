SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[usp_MES_ReclaimComponent]
	@Operator varchar(5)
,	@Serial int
,	@ComponentPart varchar(25)
,	@Quantity numeric(20,6)
,	@WODID int
,	@ComponentSerial int out
,	@TranDT datetime out
,	@Result integer out
as
set nocount on
set ansi_warnings off
set	@Result = 999999

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare
	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
save tran @ProcName
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>

declare
	@StdQuantity numeric(20,6)
,	@BreakoutQuantity numeric(20,6)
,	@BreakoutSerial int

select
	@StdQuantity = o.std_quantity
from
	object o
where
	o.serial = @Serial

if (@StdQuantity < @Quantity) begin
	/*	Break out serial (dbo.usp_InventoryControl_Breakout) */
	set @BreakoutQuantity = @Quantity - @StdQuantity
	
	--- <Call>	
	set	@CallProcName = 'dbo.usp_InventoryControl_Breakout'
	execute
		@ProcReturn = dbo.usp_InventoryControl_Breakout
		@Operator = @Operator
	,	@Serial = @Serial
	,	@QtyBreakout = @BreakoutQuantity
	,	@BreakoutSerial = @BreakoutSerial out
	,	@TranDT = @TranDT out
	,	@Result = @Result out
	
	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	--- </Call>	
	
	
	/*	Insert breakout serial into print queue */
	--- <Insert rows="*">
	set	@TableName = 'dbo.print_queue'

	insert
		dbo.print_queue
	(	printed
	,	type
	,	copies
	,	serial_number
	,	label_format
	,	server_name
	)
	select
		printed = 0
	,	type = 'W'
	,	copies = 1
	,	serial_number = @BreakoutSerial
	,	label_format = 'SMART_LABEL'
	,	server_name = 'LBLSRV'
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	--- </Insert>
end
	



/*	Generate an object of the component part by reclaim. */
/*		Get object serial. (monitor.usp_SerialBlock) */
--- <Call>	
set	@CallProcName = 'monitor.usp_NewSerialBlock'
execute
	@ProcReturn = monitor.usp_NewSerialBlock
	@SerialBlockSize = 1
,	@FirstNewSerial = @ComponentSerial out
,	@Result = @ProcResult out


set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
	return	@Result
end

if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran @ProcName
	return	@Result
end

if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
--- </Call>


/*	Create new object for reclaimed component. (i1) */
--- <Insert rows="1">
set	@TableName = 'dbo.object'

insert
	dbo.object
(
	serial
,   part
,   location
,   last_date
,   unit_measure
,   operator
,   status
,   note
,   quantity
,   last_time
,   plant
,   std_quantity
,   user_defined_status
,   workorder
)
select
	serial = @ComponentSerial
,   part = @ComponentPart
,   location = woh.MachineCode
,   last_date = @TranDT
,   unit_measure = pi.standard_unit
,   operator = @Operator
,   status = 'A'
,   note = 'Reclaim'
,   quantity = @Quantity
,   last_time = @TranDT
,   plant = l.plant
,   std_quantity = @Quantity
,   user_defined_status = 'Approved'
,   workorder = woh.WorkOrderNumber
from
	dbo.WorkOrderHeaders woh
		join dbo.WorkOrderDetails wod
			on woh.WorkOrderNumber = wod.WorkOrderNumber
			and wod.RowID = @WODID
		join dbo.location l
			on l.code = woh.MachineCode
	join dbo.part_inventory pi
		on pi.part = @ComponentPart



--- <Insert rows="1">
set	@TableName = 'dbo.audit_trail'

insert
	dbo.audit_trail
(	serial
,	date_stamp
,	type
,	part
,	quantity
,	remarks
,	po_number
,	operator
,	from_loc
,	to_loc
,	on_hand
,	lot
,	weight
,	status
,	shipper
,	unit
,	workorder
,	std_quantity
,	cost
,	custom1
,	custom2
,	custom3
,	custom4
,	custom5
,	plant
,	notes
,	package_type
,	suffix
,	due_date
,	std_cost
,	user_defined_status
,	engineering_level
,	parent_serial
,	origin
,	destination
,	sequence
,	object_type
,	part_name
,	start_date
,	field1
,	field2
,	show_on_shipper
,	tare_weight
,	kanban_number
,	dimension_qty_string
,	dim_qty_string_other
,	varying_dimension_code
)
select
    serial = o.serial
,	date_stamp = @TranDT
,	type = 'K'
,	part = @ComponentPart
,	quantity = @Quantity
,	remarks = 'Reclaim'
,	po_number = o.po_number
,	operator = @Operator
,	from_loc = @Serial
,	to_loc = o.location
,	on_hand = po.on_hand
,	lot = o.lot
,	weight = o.weight
,	status = 'A'
,	shipper = o.shipper
,	unit = o.unit_measure
,	workorder = o.workorder
,	std_quantity = @Quantity
,	cost = o.cost
,	custom1 = o.custom1
,	custom2 = o.custom2
,	custom3 = o.custom3
,	custom4 = o.custom4
,	custom5 = o.custom5
,	plant = o.plant
,	notes = 'Reclaim Component'
,	package_type = o.package_type
,	suffix = o.suffix
,	due_date = o.date_due
,	std_cost = o.std_cost
,	user_defined_status = 'Approved'
,	engineering_level = o.engineering_level
,	parent_serial = o.parent_serial
,	origin = o.origin
,	destination = o.destination
,	sequence = o.sequence
,	object_type = o.type
,	part_name = o.name
,	start_date = o.start_date
,	field1 = o.field1
,	field2 = o.field2
,	show_on_shipper = o.show_on_shipper
,	tare_weight = o.tare_weight
,	kanban_number = o.kanban_number
,	dimension_qty_string = o.dimension_qty_string
,	dim_qty_string_other = o.dim_qty_string_other
,	varying_dimension_code = o.varying_dimension_code
from
    object o
    join part_online po
        on o.part = po.part
where
    o.serial = @ComponentSerial

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Insert>




/* Either allocate the new serial to the Job if it is tied to the Job, or print the new serial label  */
declare
	@BOMPart varchar(25)
,	@WorkOrderNumber varchar(50)
,	@WorkOrderDetailLine float

set
	@BOMPart = ''

select
	@WorkOrderNumber = wodbom.WorkOrderNumber	
,	@WorkOrderDetailLine = wodbom.WorkOrderDetailLine
from
	WorkOrderDetailBillOfMaterials wodbom
where
	wodbom.RowID = @WODID
	
select
	@BOMPart = wodbom.ChildPart
from
	WorkOrderDetailBillOfMaterials wodbom
where
	wodbom.WorkOrderNumber = @WorkOrderNumber
	and wodbom.WorkOrderDetailLine = @WorkOrderDetailLine
	
if (@BOMPart <> '') begin
	--- <Call>	
	set	@CallProcName = 'usp_MES_AllocateSerial'
	execute
		@ProcReturn = dbo.usp_MES_AllocateSerial
		@Operator = @Operator
	,	@Serial = @ComponentSerial
	,	@WODID = @WODID
	,	@TranDT = @TranDT out
	,	@Result = @Result out
	
	
	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	--- </Call>	
end
else begin
	/*	Insert serial into print queue */
	--- <Insert rows="*">
	set	@TableName = 'dbo.print_queue'

	insert
		dbo.print_queue
	(	printed
	,	type
	,	copies
	,	serial_number
	,	label_format
	,	server_name
	)
	select
		printed = 0
	,	type = 'W'
	,	copies = 1
	,	serial_number = @ComponentSerial
	,	label_format = 'SMART_LABEL'
	,	server_name = 'LBLSRV'
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	--- </Insert>
end

--- </Body>

if	@TranCount = 0 begin
	commit tran @ProcName
end

---	<Return>
set	@Result = 0
return
	@Result
--- </Return>

/*
Example:
Initial queries
{

}

Test syntax
{

set statistics io on
set statistics time on
go

declare
	@Param1 [scalar_data_type]

set	@Param1 = [test_value]

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_InventoryControl_Breakout
	@Param1 = @Param1
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

if	@@trancount > 0 begin
	rollback
end
go

set statistics io off
set statistics time off
go

}

Results {
}
*/
GO
