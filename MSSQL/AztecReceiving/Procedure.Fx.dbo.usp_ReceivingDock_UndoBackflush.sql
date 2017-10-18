
/*
Create Procedure.Fx.dbo.usp_ReceivingDock_UndoBackflush.sql
*/

--use Fx
--go

if	objectproperty(object_id('dbo.usp_ReceivingDock_UndoBackflush'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_ReceivingDock_UndoBackflush
end
go

create procedure dbo.usp_ReceivingDock_UndoBackflush
	@Operator varchar(5)
,	@BackflushNumber varchar(50)
,	@ReceiverObjectID int
,	@TranDT datetime = null out
,	@Result integer = null out
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
/*	Determine total amount of backflushing to undo. */
declare
	@rows int
  
declare
	@backflushes table
(	serial int primary key
,	qtyIssued numeric(20,6)
)

insert
	@backflushes
(	serial
,	qtyIssued
)
select
	serial = bd.SerialConsumed
,	qtyIssued = sum(bd.QtyIssue - bd.QtyOverage)
from
	dbo.BackflushDetails bd
where
	bd.BackflushNumber = @BackflushNumber
group by
	bd.SerialConsumed

set	@rows = @@ROWCOUNT

/*	Recreate inventory. */
--- <Update rows="n">
  
set	@TableName = 'dbo.object'

update
	o
set
	operator = @Operator
,	quantity = o.quantity + b.qtyIssued
,	std_quantity = o.std_quantity + b.qtyIssued
,	last_date = @TranDT
,	last_time = @TranDT
from
	dbo.object o
		join @backflushes b
			on b.serial = o.serial

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != @rows begin
	--- <Insert rows="n - @RowCount">
	insert
		dbo.object
	(	serial
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
		serial = at.serial
	,   part = at.part
	,   location = at.from_loc
	,   last_date = @TranDT
	,   unit_measure = at.unit
	,   operator = @Operator
	,   status = at.status
	,   destination = at.destination
	,   station = null
	,   origin = at.origin
	,   cost = at.cost
	,   weight = dbo.fn_Inventory_GetPartNetWeight(at.part, b.qtyIssued)
	,   parent_serial = null
	,   note = 'Object recovered from backflush to ship.'
	,   quantity = dbo.udf_GetQtyFromStdQty(at.part, b.qtyIssued, at.unit)
	,   last_time = @TranDT
	,   date_due = at.due_date
	,   customer = at.customer
	,   sequence = at.sequence
	,   shipper = null
	,   lot = at.lot
	,   type = at.object_type
	,   po_number = at.po_number
	,   name = at.part_name
	,   plant = at.plant
	,   start_date = at.start_date
	,   std_quantity = b.qtyIssued
	,   package_type = at.package_type
	,   field1 = at.field1
	,   field2 = at.field2
	,   custom1 = at.custom1
	,   custom2 = at.custom2
	,   custom3 = at.custom3
	,   custom4 = at.custom4
	,   custom5 = at.custom5
	,   show_on_shipper = 'N'
	,   tare_weight = at.tare_weight
	,   suffix = at.suffix
	,   std_cost = at.std_cost
	,   user_defined_status = at.user_defined_status
	,   workorder = at.workorder
	,   engineering_level = at.engineering_level
	,   kanban_number = at.kanban_number
	,   dimension_qty_string = at.dimension_qty_string
	,   dim_qty_string_other = at.dim_qty_string_other
	,   varying_dimension_code = at.varying_dimension_code
	,   posted = at.posted
	from
		dbo.audit_trail at
			join @backflushes b
				on b.serial = at.serial
				and not exists
					(	select
							*
						from
							dbo.object
						where
							serial = b.serial
					)
	where
		at.ID = (select min(LastTransID) from dbo.InventoryControl_CycleCount_GetSerialInfo(at.serial))
	
	select
		@Error = @@Error,
		@RowCount = @RowCount + @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount != @rows begin
		set	@Result = 999999
		RAISERROR ('Error upserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, @rows)
		rollback tran @ProcName
		return
	end
	--- </Insert>
	
end
--- </Update>

/*	Create undo-material issue audit trail. */
--- <Insert rows="n">
set	@TableName = 'dbo.audit_trail'

insert
	dbo.audit_trail
(	serial
,	date_stamp
,	type
,	part
,	quantity
,	remarks
,	price
,	salesman
,	customer
,	vendor
,	po_number
,	operator
,	from_loc
,	to_loc
,	on_hand
,	lot
,	weight
,	status
,	shipper
,	flag
,	activity
,	unit
,	workorder
,	std_quantity
,	cost
,	control_number
,	custom1
,	custom2
,	custom3
,	custom4
,	custom5
,	plant
,	invoice_number
,	notes
,	gl_account
,	package_type
,	suffix
,	due_date
,	group_no
,	sales_order
,	release_no
,	dropship_shipper
,	std_cost
,	user_defined_status
,	engineering_level
,	posted
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
	at.serial
,	at.date_stamp
,	at.type
,	at.part
,	quantity = dbo.udf_GetQtyFromStdQty(at.part, -b.qtyIssued, at.unit)
,	remarks = 'Undo MI'
,	at.price
,	at.salesman
,	at.customer
,	at.vendor
,	at.po_number
,	at.operator
,	at.from_loc
,	at.to_loc
,	at.on_hand
,	at.lot
,	at.weight
,	at.status
,	at.shipper
,	at.flag
,	at.activity
,	at.unit
,	at.workorder
,	std_quantity = -b.qtyIssued
,	at.cost
,	at.control_number
,	at.custom1
,	at.custom2
,	at.custom3
,	at.custom4
,	at.custom5
,	at.plant
,	at.invoice_number
,	notes = 'Object recovered from backflush to ship.'
,	at.gl_account
,	at.package_type
,	at.suffix
,	at.due_date
,	at.group_no
,	at.sales_order
,	at.release_no
,	at.dropship_shipper
,	at.std_cost
,	at.user_defined_status
,	at.engineering_level
,	posted = 'N'
,	at.parent_serial
,	at.origin
,	at.destination
,	at.sequence
,	at.object_type
,	at.part_name
,	at.start_date
,	at.field1
,	at.field2
,	at.show_on_shipper
,	at.tare_weight
,	at.kanban_number
,	at.dimension_qty_string
,	at.dim_qty_string_other
,	at.varying_dimension_code
from
	@backflushes b
	join dbo.BackflushHeaders bh
		on bh.BackflushNumber = @BackflushNumber
	join dbo.audit_trail at
		on at.serial = b.serial
		and at.type = 'M'
		and at.date_stamp = bh.TranDT

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != @rows begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, @rows)
	rollback tran @ProcName
	return
end
--- </Insert>

/*	Mark backflush records as undone.*/
--- <Update rows="1">
set	@TableName = 'dbo.BackflushHeaders'

update
	bh
set
	Status = -1 --(select dbo.udf_StatusValue ('dbo.BackflushHeaders', 'Deleted'))
,	RowModifiedDT = @TranDT
from
	dbo.BackflushHeaders bh
where
	bh.BackflushNumber = @BackflushNumber

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

--- <Update rows="*">
set	@TableName = 'dbo.BackflushDetails'

update
	bd
set
	Status = -1 --(select dbo.udf_StatusValue ('dbo.BackflushDetails', 'Deleted'))
,	RowModifiedDT = @TranDT
from
	dbo.BackflushDetails bd
where
	bd.BackflushNumber = @BackflushNumber

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Update>
--- </Body>

---	<CloseTran AutoCommit=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
---	</CloseTran AutoCommit=Yes>

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
	@Operator varchar(5)
,	@BackflushNumber varchar(50)
,	@ReceiverObjectID int

set	@Operator = 'EES'
set	@BackflushNumber = 'BF_0000019980'
set	@ReceiverObjectID = null

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_ReceivingDock_UndoBackflush
	@Operator = @Operator
,	@BackflushNumber = @BackflushNumber
,	@ReceiverObjectID = @ReceiverObjectID
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult


select
	*
from
	dbo.BackflushHeaders bh
where
	bh.BackflushNumber = @BackflushNumber

select
	*
from
	dbo.BackflushDetails bd
where
	bd.BackflushNumber = @BackflushNumber

select
	atM.*
from
	dbo.BackflushHeaders bh
	join dbo.BackflushDetails bd
		on bd.BackflushNumber = bh.BackflushNumber
	join dbo.audit_trail atM
		on atM.serial = bd.SerialConsumed
		and atM.type = 'M'
		and atM.date_stamp in (bh.TranDT, bh.RowModifiedDT)
where
	bh.BackflushNumber = @BackflushNumber
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
go

