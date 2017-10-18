
/*
Create procedure fx21st.dbo.usp_MES_NewScrapEntry
*/

--use fx21st
--go

if	objectproperty(object_id('dbo.usp_MES_NewScrapEntry'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_MES_NewScrapEntry
end
go

create procedure dbo.usp_MES_NewScrapEntry
	@Operator varchar(5)
,	@WODID int
,	@Serial int
,	@QtyScrap numeric(20, 6)
,	@DefectCode varchar(10)
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
/*	Operator required:  */
if	not exists
	(	select
			1
		from
			employee
		where
			operator_code = @Operator
	) begin

	set @Result = 60001
	RAISERROR ('Invalid operator code %s in procedure %s.  Error: %d', 16, 1, @Operator, @ProcName, @Error)
	rollback tran @ProcName
	return
end

/*	WOD ID must be valid:  */
if	not exists
	(	select
			*
		from
			dbo.WorkOrderDetails wod
		where
			RowID = @WODID
	) begin

	set	@Result = 200101
	RAISERROR ('Invalid job id %d in procedure %s.  Error: %d', 16, 1, @WODID, @ProcName, @Error)
	rollback tran @ProcName
	return
end

/*	Defect code must be valid:  */
if	not exists
	(	select
			*
		from
			dbo.defect_codes dc
		where
			dc.code = @DefectCode
	) begin

	set	@Result = 200101
	RAISERROR ('Invalid defect code %s in procedure %s.  Error: %d', 16, 1, @DefectCode, @ProcName, @Error)
	rollback tran @ProcName
	return
end

/*	Quantity must be valid:  */
if	not coalesce(@QtyScrap, 0) > 0 begin

	set	@Result = 200101
	RAISERROR ('Invalid defect quantity %d in procedure %s.  Error: %d', 16, 1, @QtyScrap, @ProcName, @Error)
	rollback tran @ProcName
	return
end
---	</ArgumentValidation>

--- <Body>
/*	Report overage for scrap in excess of material. */
declare
	@qtyExcess numeric(20,6)

set	@qtyExcess = @QtyScrap - coalesce
	(	(	select
	 			std_quantity
	 		from
	 			dbo.object o
	 		where
	 			o.serial = @Serial
	 	)
	,	0
	)
set	@qtyExcess = case when @qtyExcess < 0 then 0 end

if	@qtyExcess > 0 begin
	--- <Call>	
	set	@CallProcName = 'dbo.usp_MES_NewExcessQty'
	execute
		@ProcReturn = dbo.usp_MES_NewExcessQty
			@Operator = @Operator
		,	@WODID = @WODID
		,	@Serial = @Serial
		,	@QtyExcess = @qtyExcess
		,	@ExcessReason = 'Excess due to scrap.'
		,	@TranDT = @TranDT
		,	@Result = @Result
	
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

/*	Adjust object quantity for scrap. */
--- <Update rows="1">
set	@TableName = '[tableName]'

update
	o
set
	quantity = o.quantity - @QtyScrap
,	std_quantity = o.std_quantity - @QtyScrap
from
	dbo.object o
where
	o.serial = @Serial

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

/*	Create quality audit trail. */
--- <Insert rows="1">
set	@TableName = 'dbo.audit_trail'

insert  dbo.audit_trail
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
,	type = 'Q'
,	part = object.part
,	quantity = @QtyScrap
,	remarks = 'Quality'
,	po_number = object.po_number
,	operator = @Operator
,	from_loc = object.status
,	to_loc = 'S'
,	on_hand = part_online.on_hand - @QtyScrap
,	lot = object.lot
,	weight = object.weight
,	status = object.status
,	shipper = object.shipper
,	unit = object.unit_measure
,	workorder = convert (varchar,@WODID)
,	std_quantity = @QtyScrap
,	cost = object.cost
,	custom1 = object.custom1
,	custom2 = object.custom2
,	custom3 = object.custom3
,	custom4 = object.custom4
,	custom5 = object.custom5
,	plant = object.plant
,	notes = ''
,	package_type = object.package_type
,	suffix = object.suffix
,	due_date = object.date_due
,	std_cost = object.std_cost
,	user_defined_status = object.user_defined_status
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

declare
	@qualityAuditTrailID int

set	@qualityAuditTrailID = SCOPE_IDENTITY() 

--- </Insert>

/*	Create defect entry. */ 
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
,	Machine = woh.MachineCode
,	Part = o.part
,	DefectCode = @DefectCode
,	QtyScrapped = @QtyScrap
,	Operator = @Operator
,	Shift = 0 --Refactor
,	WODID = @WODID
,	DefectSerial = @Serial
,	AuditTrailID = @qualityAuditTrailID
from
	dbo.object o
	join dbo.WorkOrderHeaders woh
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

/*	Delete object if quantity remaining is zero. */
if	exists
	(	select
 			*
 		from
 			dbo.object o
 		where
 			serial = @serial
 			and o.std_quantity <= 0
	) begin
	
	--- <Delete rows="1">
	set	@TableName = 'dbo.object'
	 
	delete
		o
	from
		dbo.object o
	where
		serial = @serial	 

	select
		@Error = @@Error,
		@RowCount = @@Rowcount

	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount != 1 begin
		set	@Result = 999999
		RAISERROR ('Error deleting from table %s in procedure %s.  Rows deleted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Delete>
end

/*	Adjust part on hand qty.*/
/*		Update part on hand quantity.  */
--- <Update rows="1">
set	@TableName = 'dbo.part_online'

update
	po
set 
	on_hand =
	(	select
			sum(o2.std_quantity)
		from
			object o2
		where
			o2.part = po.part
			and o2.status = 'A'
	)
from
	dbo.part_online po
	join dbo.object o
		on o.part = po.part
where
	o.serial = @Serial

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
	--- <Insert rows="1">
	set	@TableName = 'dbo.part_online'
	
	insert
		dbo.part_online
	(	part
	,	on_hand
	)
	select
		part = o.part
	,	on_hand = sum(o.std_quantity)
	from
		dbo.object o
	where
		o.part =
		(	select
				o2.part
			from
				dbo.object o2
			where
				o2.serial = @Serial
		)
		and status = 'A'
	group by
		o.part
	
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
	
end
--- </Update>
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
	@Operator varchar(5)
,	@WODID int
,	@Serial int
,	@QtyScrap numeric(20, 6)
,	@DefectCode varchar(10)

set	@Operator = 'mon'
set @WODID = 6
set @Serial = -1
set @QtyScrap = 100
set @DefectCode = ''

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_MES_NewScrapEntry
	@Operator = @Operator
,	@WODID = @WODID
,	@Serial = @Serial
,	@QtyScrap = @QtyScrap
,	@DefectCode = @DefectCode
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
go

