SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_InventoryControl_Breakout]
	@Operator varchar(5)
,	@Serial int
,	@QtyBreakout numeric(20,6)
,	@BreakoutSerial int out
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
/*	Get object serial. (monitor.usp_SerialBlock) */
--- <Call>	
set	@CallProcName = 'monitor.usp_NewSerialBlock'
execute
	@ProcReturn = monitor.usp_NewSerialBlock
	@SerialBlockSize = 1
,	@FirstNewSerial = @BreakoutSerial out
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

/*	Create new object for breakout quantity. (i1) */
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
,   destination
,   station
,   origin
,   cost
,   weight
,   parent_serial
,   note
,   quantity
,   last_time
,   date_due
,   customer
,   sequence
,   shipper
,   lot
,   type
,   po_number
,   name
,   plant
,   start_date
,   std_quantity
,   package_type
,   field1
,   field2
,   custom1
,   custom2
,   custom3
,   custom4
,   custom5
,   show_on_shipper
,   tare_weight
,   suffix
,   std_cost
,   user_defined_status
,   workorder
,   engineering_level
,   kanban_number
,   dimension_qty_string
,   dim_qty_string_other
,   varying_dimension_code
,   posted
)
select
	serial = @BreakoutSerial
,   part = o.part
,   location = o.location
,   last_date = @TranDT
,   unit_measure = o.unit_measure
,   operator = @Operator
,   status = o.status
,   destination = o.destination
,   station = o.station
,   origin = o.origin
,   cost = o.cost
,   weight = null
,   parent_serial = null
,   note = o.note
,   quantity = dbo.udf_GetQtyFromStdQty(o.part, @QtyBreakout, o.unit_measure)
,   last_time = @TranDT
,   date_due = o.date_due
,   customer = o.customer
,   sequence = o.sequence
,   shipper = o.shipper
,   lot = o.lot
,   type = o.type
,   po_number = o.po_number
,   name = o.name
,   plant = o.plant
,   start_date = o.start_date
,   std_quantity = @QtyBreakout
,   package_type = o.package_type
,   field1 = o.field1
,   field2 = o.field2
,   custom1 = o.custom1
,   custom2 = o.custom2
,   custom3 = o.custom3
,   custom4 = o.custom4
,   custom5 = o.custom5
,   show_on_shipper = o.show_on_shipper
,   tare_weight = o.tare_weight
,   suffix = o.suffix
,   std_cost = o.std_cost
,   user_defined_status = o.user_defined_status
,   workorder = o.workorder
,   engineering_level = o.engineering_level
,   kanban_number = o.kanban_number
,   dimension_qty_string = o.dimension_qty_string
,   dim_qty_string_other = o.dim_qty_string_other
,   varying_dimension_code = o.varying_dimension_code
,   posted = o.posted
from
	dbo.object o
where
	serial = @Serial	

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

/*	Adjust quantity of broken object. (u1) */
--- <Update rows="1">
set	@TableName = 'dbo.object'

update
	o
set
	std_quantity = std_quantity - @QtyBreakout
,	quantity = quantity - dbo.udf_GetQtyFromStdQty(o.part, @QtyBreakout, o.unit_measure)
from
	dbo.object o
where
	serial = @Serial

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update>

/*	Create breakout audit trail. (i1) */
declare
	@BreakoutATType char(1)
,	@BreakoutATRemarks varchar(10)

set	@BreakoutATType = 'B'
set @BreakoutATRemarks = 'Break Out'

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
,   type = @BreakoutATType
,   part = o.part
,   quantity = o.quantity
,   remarks = @BreakoutATRemarks
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
	serial = @BreakoutSerial

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

/*	Create 2nd breakout audit trail. (i1) */
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
,   type = @BreakoutATType
,   part = o.part
,   quantity = o.quantity
,   remarks = @BreakoutATRemarks
,   price = 0
,   salesman = ''
,   customer = o.customer
,   vendor = ''
,   po_number = o.po_number
,   operator = @Operator
,   from_loc = o.location
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
	serial = @Serial

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

--- </Body>

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
