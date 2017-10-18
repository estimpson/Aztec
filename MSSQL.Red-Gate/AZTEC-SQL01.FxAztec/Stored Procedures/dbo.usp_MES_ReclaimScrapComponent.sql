SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_MES_ReclaimScrapComponent]
	@Operator varchar(10)
,	@Serial int
,	@ComponentPart varchar(25)
,	@Qty numeric(20,6)
,	@WODID int
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
else begin
	save tran @ProcName
end
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	If necessary, perform a breakout from the serial being reclaimed from. */
if	(	select
			o.std_quantity
		from
			dbo.object o
		where
			serial = @Serial
	) > @Qty begin
	
	declare
		@qtyBreakout numeric(20,6)
	
	select
		@qtyBreakout =
			(	select
					o.std_quantity
				from
					dbo.object o
				where
					serial = @Serial
			) - @Qty	
	
	--- <Call>
	declare
		@breakoutSerial int
	
	set	@CallProcName = 'dbo.usp_InventoryControl_Breakout'
	execute
		@ProcReturn = dbo.usp_InventoryControl_Breakout
		@Operator = @Operator
	,	@Serial = @Serial
	,	@QtyBreakout = @qtyBreakout
	,	@BreakoutSerial = @breakoutSerial out
	,	@TranDT = @TranDT out
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
	
	/*	Generate label for breakout serial. */
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
	,	serial_number = @breakoutSerial
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
declare
	@componentSerial int

set	@CallProcName = 'monitor.usp_NewSerialBlock'
execute
	@ProcReturn = monitor.usp_NewSerialBlock
	@SerialBlockSize = 1
,	@FirstNewSerial = @componentSerial out
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

/*		Create new object for reclaimed component. (i1) */
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
	serial = @componentSerial
,   part = @ComponentPart
,   location = woh.MachineCode
,   last_date = @TranDT
,   unit_measure = pi.standard_unit
,   operator = @Operator
,   status = 'S'
,   note = 'Scrap during reclaim.'
,   quantity = @Qty
,   last_time = @TranDT
,   plant = l.plant
,   std_quantity = @Qty
,   user_defined_status = 'Scrapped'
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

/*	Create reclaim audit trail. (i1) */
declare
	@reclaimATType char(1)
,	@reclaimATRemarks varchar(10)

set	@reclaimATType = 'K'
set @reclaimATRemarks = 'Reclaim'

--- <Insert rows="1">
set	@TableName = 'dbo.audit_trail'

insert
	dbo.audit_trail
(
	serial
,   date_stamp
,   type
,   part
,   quantity
,   remarks
,   price
,   salesman
,   customer
,   vendor
,   po_number
,   operator
,   from_loc
,   to_loc
,   on_hand
,   lot
,   weight
,   status
,   shipper
,   flag
,   activity
,   unit
,   workorder
,   std_quantity
,   cost
,   control_number
,   custom1
,   custom2
,   custom3
,   custom4
,   custom5
,   plant
,   invoice_number
,   notes
,   gl_account
,   package_type
,   suffix
,   due_date
,   group_no
,   sales_order
,   release_no
,   dropship_shipper
,   std_cost
,   user_defined_status
,   engineering_level
,   posted
,   parent_serial
,   origin
,   destination
,   sequence
,   object_type
,   part_name
,   start_date
,   field1
,   field2
,   show_on_shipper
,   tare_weight
,   kanban_number
,   dimension_qty_string
,   dim_qty_string_other
,   varying_dimension_code
)
select
	serial = o.serial
,   date_stamp = @TranDT
,   type = @reclaimATType
,   part = o.part
,   quantity = o.quantity
,   remarks = @reclaimATRemarks
,   price = 0
,   salesman = ''
,   customer = o.customer
,   vendor = ''
,   po_number = o.po_number
,   operator = @Operator
,   from_loc = convert(varchar, @Serial)
,   to_loc = o.location
,   on_hand = dbo.udf_GetPartQtyOnHand(o.part)
,   lot = o.lot
,   weight = o.weight
,   status = o.status
,   shipper = o.shipper
,   flag = ''
,   activity = ''
,   unit = o.unit_measure
,   workorder = o.workorder
,   std_quantity = o.std_quantity
,   cost = o.cost
,   control_number = ''
,   custom1 = o.custom1
,   custom2 = o.custom2
,   custom3 = o.custom3
,   custom4 = o.custom4
,   custom5 = o.custom5
,   plant = o.plant
,   invoice_number = ''
,   notes = o.note
,   gl_account = ''
,   package_type = o.package_type
,   suffix = o.suffix
,   due_date = o.date_due
,   group_no = ''
,   sales_order = ''
,   release_no = ''
,   dropship_shipper = 0
,   std_cost = o.std_cost
,   user_defined_status = o.user_defined_status
,   engineering_level = o.engineering_level
,   posted = o.posted
,   parent_serial = o.parent_serial
,   origin = o.origin
,   destination = o.destination
,   sequence = o.sequence
,   object_type = o.type
,   part_name = (select name from part where part = o.part)
,   start_date = o.start_date
,   field1 = o.field1
,   field2 = o.field2
,   show_on_shipper = o.show_on_shipper
,   tare_weight = o.tare_weight
,   kanban_number = o.kanban_number
,   dimension_qty_string = o.dimension_qty_string
,   dim_qty_string_other = o.dim_qty_string_other
,   varying_dimension_code = o.varying_dimension_code
from
	dbo.object o
where
	serial = @componentSerial

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

/*	Scrap the reclaimed object. */
--- <Call>	
set	@CallProcName = 'dbo.usp_MES_NewScrapEntry'
execute
	@ProcReturn = dbo.usp_MES_NewScrapEntry
	@Operator = @Operator
,	@WODID = @WODID
,	@Serial = @componentSerial
,	@QtyScrap = @Qty
,	@DefectCode = 'Reclaim'
,	@TranDT = @TranDT out
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
select
	wod.RowID, wod.PartCode, woh.*, wod.*
from
	dbo.WorkOrderHeaders woh
	join dbo.WorkOrderDetails wod
		on wod.WorkOrderNumber = woh.WorkOrderNumber

select
	*
from
	dbo.object o
where
	part like '12%21B'
	and serial = 1833131

select
	*
from
	FT.XRt xr
where
	xr.TopPart = '1231SW21B'
	and xr.BOMLevel = 1

}

Test syntax
{

set statistics io on
set statistics time on
go

declare
	@Operator varchar(10)
,	@Serial int
,	@ComponentPart varchar(25)
,	@Qty numeric(20,6)
,	@WODID int

set	@Operator = 'EES'
set @Serial = 1833131
set @ComponentPart = '120021B'
set @Qty = 6
set @WODID = 86

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_MES_ReclaimScrapComponent
	@Operator = @Operator
,	@Serial = @Serial
,	@ComponentPart = @ComponentPart
,	@Qty = @Qty
,	@WODID = @WODID
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
