SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_MES_NewExcessQty]
	@Operator varchar(5)
,	@WODID int
,	@Serial int
,	@QtyExcess numeric (20,6)
,	@ExcessReason varchar(255)
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
/*	Recreate object if necessary. */
if	not exists
	(	select
			*
		from
			dbo.object o
		where
			serial = @Serial
	) begin

	--- <Insert rows="1">
	set	@TableName = 'dbo.object'
	
	insert
		dbo.object
	(	serial
	,	part
	,	location
	,	last_date
	,	quantity
	,	po_number
	,	operator
	,	lot
	,	weight
	,	status
	,	shipper
	,	unit_measure
	,	workorder
	,	std_quantity
	,	cost
	,	custom1
	,	custom2
	,	custom3
	,	custom4
	,	custom5
	,	plant
	,	package_type
	,	suffix
	,	date_due
	,	std_cost
	,	user_defined_status
	,	engineering_level
	,	parent_serial
	,	origin
	,	destination
	,	sequence
	,	type
	,	name
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
		serial = atLasttrans.serial
	,	part = atLasttrans.part
	,	location = 'Qty Excess'
	,	last_date = @TranDT
	,	quantity = dbo.udf_GetQtyFromStdQty(atLasttrans.part, @QtyExcess, atLasttrans.unit)
	,	po_number = atLasttrans.po_number
	,	operator = @Operator
	,	lot = atLasttrans.lot
	,	weight = atLasttrans.weight
	,	status = 'S'
	,	shipper = atLasttrans.shipper
	,	unit = atLasttrans.unit
	,	workorder = convert (varchar, @WODID)
	,	std_quantity = @QtyExcess
	,	cost = atLasttrans.cost
	,	custom1 = atLasttrans.custom1
	,	custom2 = atLasttrans.custom2
	,	custom3 = atLasttrans.custom3
	,	custom4 = atLasttrans.custom4
	,	custom5 = atLasttrans.custom5
	,	plant = atLasttrans.plant
	,	package_type = atLasttrans.package_type
	,	suffix = atLasttrans.suffix
	,	date_due = atLasttrans.due_date
	,	std_cost = atLasttrans.std_cost
	,	user_defined_status = 'Scrap'
	,	engineering_level = atLasttrans.engineering_level
	,	parent_serial = atLasttrans.parent_serial
	,	origin = atLasttrans.origin
	,	destination = atLasttrans.destination
	,	sequence = atLasttrans.sequence
	,	type = atLasttrans.object_type
	,	name = atLasttrans.part_name
	,	start_date = atLasttrans.start_date
	,	field1 = atLasttrans.field1
	,	field2 = atLasttrans.field2
	,	show_on_shipper = atLasttrans.show_on_shipper
	,	tare_weight = atLasttrans.tare_weight
	,	kanban_number = atLasttrans.kanban_number
	,	dimension_qty_string = atLasttrans.dimension_qty_string
	,	dim_qty_string_other = atLasttrans.dim_qty_string_other
	,	varying_dimension_code = atLasttrans.varying_dimension_code
	from
		audit_trail atLasttrans
		join part_online
			on atLasttrans.part = part_online.part
	where
		atLasttrans.serial = @Serial
		and atLasttrans.id =
		(	select
				max(id)
			from
				dbo.audit_trail at
			where
				serial = @Serial
		)
	
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
end
	--- </Insert>
else begin
	--- <Update rows="1">
	set	@TableName = 'dbo.object'
	
	update
		o
	set
		quantity = coalesce(dbo.udf_GetQtyFromStdQty(o.part, o.std_quantity + @QtyExcess, o.unit_measure), o.std_quantity + @QtyExcess)
	,	std_quantity = o.std_quantity + @QtyExcess
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
end

/*	Create excess audit trail.*/
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
    serial = object.serial
,	date_stamp = @TranDT
,	type = 'E'
,	part = object.part
,	quantity = coalesce(dbo.udf_GetQtyFromStdQty(object.part, object.std_quantity + @QtyExcess, object.unit_measure), object.std_quantity + @QtyExcess)
,	remarks = 'Qty Excess'
,	po_number = object.po_number
,	operator = @Operator
,	from_loc = object.location
,	to_loc = 'Scrap'
,	on_hand = part_online.on_hand + @QtyExcess
,	lot = object.lot
,	weight = object.weight
,	status = 'S'
,	shipper = object.shipper
,	unit = object.unit_measure
,	workorder = convert (varchar, @WODID)
,	std_quantity = @QtyExcess
,	cost = object.cost
,	custom1 = object.custom1
,	custom2 = object.custom2
,	custom3 = object.custom3
,	custom4 = object.custom4
,	custom5 = object.custom5
,	plant = object.plant
,	notes = @ExcessReason
,	package_type = object.package_type
,	suffix = object.suffix
,	due_date = object.date_due
,	std_cost = object.std_cost
,	user_defined_status = 'Scrap'
,	engineering_level = object.engineering_level
,	parent_serial = object.parent_serial
,	origin = object.origin
,	destination = object.destination
,	sequence = object.sequence
,	object_type = object.type
,	part_name = object.name
,	start_date = object.start_date
,	field1 = object.field1
,	field2 = object.field2
,	show_on_shipper = object.show_on_shipper
,	tare_weight = object.tare_weight
,	kanban_number = object.kanban_number
,	dimension_qty_string = object.dimension_qty_string
,	dim_qty_string_other = object.dim_qty_string_other
,	varying_dimension_code = object.varying_dimension_code
from
    object
    join part_online
        on object.part = part_online.part
where
    object.serial = @Serial

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
declare
	@excessAuditTrailID int

set	@excessAuditTrailID = SCOPE_IDENTITY() 

/*	Create excess defect (negative).  */
--- <Insert rows="1">
set	@TableName = 'dbo.Defects'

insert
	dbo.Defects
(	TransactionDT
,	Machine
,	Part
,	DefectCode
,	QtyScrapped
,	Operator
,	Shift
,	WODID
,	DefectSerial
,	AuditTrailID
)
select
	TransactionDT = @TranDT
,	Machine = coalesce
		(	woh.MachineCode
		,	(	select
		 			pm.machine
		 		from
		 			dbo.part_machine pm
				where
					pm.part = o.part
					and pm.sequence =
						(	select
								min(pm2.sequence)
							from
								dbo.part_machine pm2
							where
								pm2.part = o.part
						)
		 	)
		,	o.location
		)
,	Part = o.part
,	DefectCode = 'Qty Excess'
,	QtyScrapped = -@QtyExcess
,	Operator = @Operator
,	Shift = 0 --Refactor
,	WODID = @WODID
,	DefectSerial = @Serial
,	@excessAuditTrailID
from
    dbo.object o
    left join dbo.WorkOrderHeaders woh
		join dbo.WorkOrderDetails wod
			on wod.WorkOrderNumber = woh.WorkOrderNumber
		on wod.RowID = @WODID
where
    o.serial = @Serial

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

--- <CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </CloseTran Required=Yes AutoCreate=Yes>

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
,	@WODID int
,	@Serial int
,	@QtyExcess numeric (20,6)
,	@ExcessReason varchar(255)

set	@Operator = 'mon'
set	@WODID = '6'
set	@Serial = -1
set	@QtyExcess = 100
set	@ExcessReason = 'Excess due to backflush.'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_MES_NewExcessQty
	@Operator = @Operator
,	@WODID = @WODID
,	@Serial = @Serial
,	@QtyExcess = @QtyExcess
,	@ExcessReason = @ExcessReason
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
