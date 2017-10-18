SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_MES_NewShortageQty]
	@Operator varchar(5)
,	@WODID int = null
,	@Serial int
,	@QtyShort numeric (20,6)
,	@ShortageReason varchar(255)
,	@MakeEquivalentExcess bit = 0
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

--- <Update rows="1">
set	@TableName = 'dbo.object'

update
	o
set
	quantity = o.quantity - @QtyShort
,	std_quantity = o.std_quantity - @QtyShort
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


/*	Create shortage audit trail.*/
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
,	quantity = -@QtyShort
,	remarks = 'Qty Shortage'
,	po_number = object.po_number
,	operator = @Operator
,	from_loc = object.location
,	to_loc = 'Scrap'
,	on_hand = part_online.on_hand - @QtyShort
,	lot = object.lot
,	weight = object.weight
,	status = 'S'
,	shipper = object.shipper
,	unit = object.unit_measure
,	workorder = case 
					when @WODID is not null then convert(varchar, @WODID) 
					else null
					end
,	std_quantity = @QtyShort
,	cost = object.cost
,	custom1 = object.custom1
,	custom2 = object.custom2
,	custom3 = object.custom3
,	custom4 = object.custom4
,	custom5 = object.custom5
,	plant = object.plant
,	notes = @ShortageReason
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
	@shortageAuditTrailID int

set	@shortageAuditTrailID = SCOPE_IDENTITY() 

/*	Create shortage defect (positive).  */
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
,	Machine = coalesce(woh.MachineCode, o.location)
,	Part = o.part
,	DefectCode = 'Qty Shortage'
,	QtyScrapped = + @QtyShort
,	Operator = @Operator
,	Shift = 0 --Refactor
,	WODID = @WODID
,	DefectSerial = @Serial
,	@shortageAuditTrailID
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

/*	Add an equal amount of material that exists at the same location with the same part number if found. */
if	@MakeEquivalentExcess = 1 begin
	declare
		@excessSerial int
		
	select top 1
		@excessSerial = oAvailable.serial
	from
		dbo.object oAvailable
		join dbo.object oShortage
			on oShortage.Serial = @Serial 
	where
		oAvailable.status = 'A'
		and oAvailable.location = oShortage.location
		and oAvailable.part = oShortage.part
		and oAvailable.serial != oShortage.serial
	order by
		coalesce
		(	(	select
					max(atTransfer.date_stamp)
				from
					dbo.audit_trail atTransfer
				where
					atTransfer.Serial = oAvailable.serial
					and atTransfer.type = 'T'
			)
		,	(	select
					max(atBreak.date_stamp)
				from
					dbo.audit_trail atBreak
				where
					atBreak.Serial = oAvailable.serial
					and atBreak.type = 'B'
			)
		)
	
	if	@excessSerial > 0 begin
		--- <Call>
		set	@CallProcName = 'dbo.usp_MES_NewExcessQty'
		execute
			@ProcReturn = dbo.usp_MES_NewExcessQty
			@Operator = @Operator
		,	@WODID = @WODID
		,	@Serial = @excessSerial
		,	@QtyExcess = @QtyShort
		,	@ExcessReason = 'Material used out of sequence.'
		,	@MakeEquivalentShortage = 0
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
	end
end
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
,	@QtyShort numeric (20,6)
,	@ShortageReason varchar(255)

set	@Operator = 'mon'
set	@WODID = '6'
set	@Serial = -1
set	@QtyShort = 100
set	@ShortageReason = 'Shortage due to backflush.'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_MES_NewShortageQty
	@Operator = @Operator
,	@WODID = @WODID
,	@Serial = @Serial
,	@QtyShort = @QtyShort
,	@ShortageReason = @ShortageReason
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
