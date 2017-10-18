SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_InventoryControl_JobComplete]
	@Operator varchar(5)
,	@WorkOrderNumber varchar(25)
,	@WorkOrderDetailLine float
,	@PartCode varchar(25)
,	@QtyProduced numeric(20,6)
,	@Lot varchar(20)
,	@Field1 varchar(10)
,	@Field2 varchar(10)
,	@Custom1 varchar(50)
,	@Custom2 varchar(50)
,	@Custom3 varchar(50)
,	@Custom4 varchar(50)
,	@Custom5 varchar(50)
,	@Notes varchar(254)
,	@NewSerial int out
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
/*	Valid operator. */
/*	Part matches work order. */
/*	Quantity greater than zero. */
/*	Quantity matches standard pack rules (less than, more than, or equal to) for part. */
/*	Calculate the maximum production quantity for allocated inventory. */
/*		Quantity does not exceed the maximum. */

---	</ArgumentValidation>

--- <Body>
/*	Get object serial. (monitor.usp_NewSerialBlock) */
--- <Call>	
set	@CallProcName = 'monitor.usp_NewSerialBlock'
execute
	@ProcReturn = monitor.usp_NewSerialBlock
	@SerialBlockSize = 1
,	@FirstNewSerial = @NewSerial
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

/*	Create new object. (i1) */
--- <Insert rows="1">
set	@TableName = 'dbo.object'

insert
	dbo.object
(
	serial
,	part
,	lot
,	location
,	last_date
,	unit_measure
,	operator
,	status
,	cost
,	weight
,	note
,	name
,	plant
,	quantity
,	last_time
,	std_quantity
,	field1
,	field2
,	custom1
,	custom2
,	custom3
,	custom4
,	custom5
,	user_defined_status
,	workorder
,	std_cost
)
select
	serial = @NewSerial
,	part = @PartCode
,	lot = @Lot
,	location = woh.MachineCode
,	last_date = @TranDT
,	unit_measure = pi.standard_unit
,	operator = @Operator
,	status =
	case
		when p.quality_alert = 'Y' then 'H'
		else 'A'
	end
,	cost = ps.cost_cum
,	weight = dbo.udf_GetPartNetWeight(@PartCode, @QtyProduced)
,	note =
	case
		when p.quality_alert = 'Y' then p.description_long
	end
,	name = p.name
,	plant = (select plant from dbo.location where code = woh.MachineCode)
,	quantity = @QtyProduced
,	last_time = @TranDT
,	std_quantity = @QtyProduced
,	field1 = @Field1
,	field2 = @Field2
,	custom1 = @Custom1
,	custom2 = @Custom2
,	custom3 = @Custom3
,	custom4 = @Custom4
,	custom5 = @Custom5
,	user_defined_status =
	case
		when p.quality_alert = 'Y' then 'Hold'
		else 'Approved'
	end
,	workorder = @WorkOrderNumber
,	std_cost = ps.cost_cum
from
	dbo.part p
	join dbo.WorkOrderHeaders woh on
		woh.WorkOrderNumber = @WorkOrderNumber
	join dbo.WorkOrderDetails wod on
		wod.WorkOrderNumber = @WorkOrderNumber
		and
			wod.Line = @WorkOrderDetailLine
		and
			wod.PartCode = @PartCode
	join dbo.part_inventory pi on
		pi.part = @PartCode
	join dbo.part_standard ps on
		ps.part = @PartCode
where
	p.part = @PartCode

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

/*	Create job complete audit trail. (i1) */
declare
	@jobCompleteATType char(1)
,	@jobCompleteATRemarks char(1)

set	@jobCompleteATType = 'M'
set @jobCompleteATRemarks = 'Job comp'

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
,   type = @jobCompleteATType
,   part = o.part
,   quantity = o.quantity
,   remarks = @jobCompleteATRemarks
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
,   notes = @Notes
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
	serial = @NewSerial

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

/*	Record part on hand. (dbo.usp_InventoryControl_UpdatePartOnHand) */
--- <Call>	
set	@CallProcName = 'dbo.usp_InventoryControl_UpdatePartOnHand'
execute
	@ProcReturn = dbo.usp_InventoryControl_UpdatePartOnHand
	@PartCode = @PartCode
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
	@ProcReturn = dbo.usp_InventoryControl_JobComplete
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
