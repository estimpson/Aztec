
/*
Create procedure fx21stPilot.dbo.usp_MES_JCPreObject
*/

--use fx21stPilot
--go

if	objectproperty(object_id('dbo.usp_MES_JCPreObject'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_MES_JCPreObject
end
go

create procedure dbo.usp_MES_JCPreObject
	@Operator varchar (10)
,	@PreObjectSerial int
,	@TranDT datetime out
,	@Result int out
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

if	coalesce
	(	(	select
				max(part)
			from
				audit_trail
			where
				serial = @PreObjectSerial
			)
	,	''
	) = 'PALLET' begin
	set @Result = 0
	rollback tran @ProcName
	return	@Result
end

/*	Serial must be a Pre-Object:  */
if	not exists
	(	select
			*
		from
			dbo.WorkOrderObjects
		where
			Serial = @PreObjectSerial
	) begin
	set @Result = 100101
	RAISERROR ('Invalid pre-object serial %d in procedure %s.  Error: %d', 16, 1, @PreObjectSerial, @ProcName, @Error)
	rollback tran @ProcName
	return
end

/*	If PreObject has already been Job Completed, do nothing:  */
if	exists
	(	select
			*
		from
			audit_trail
		where
			type = 'J'
			and serial = @PreObjectSerial
	) begin
	set	@Result = 100100
	RAISERROR ('Serial %d already job completed in procedure %s.  Warning: %d', 10, 1, @PreObjectSerial, @ProcName, @Error)
	rollback tran @ProcName
	return
end

/*	Quantity must be valid:  */
declare
	@QtyRequested numeric(20,6)

select
	@QtyRequested = woo.Quantity
from
	dbo.WorkOrderObjects woo
where
	woo.Serial = @PreObjectSerial

if	not coalesce(@QtyRequested, 0) > 0 begin
	set @Result = 202001
	RAISERROR ('Invalid quantity requested %d in procedure %s.  Error: %d', 16, 1, @QtyRequested, @ProcName, @Error)
	rollback tran @ProcName
	return
end

/*	WOD ID must be valid:  */
declare
	@WODID int
,	@Part varchar(25)

select
	@WODID = wod.RowID
,	@Part = woo.PartCode
from
	dbo.WorkOrderObjects woo
	join dbo.WorkOrderDetails wod
		on wod.WorkOrderNumber = woo.WorkOrderNumber
		and wod.Line = woo.WorkOrderDetailLine
where
	woo.Serial = @PreObjectSerial

if	not exists
	(	select
			*
		from
			dbo.WorkOrderDetails wod
		where
			wod.RowID = @WODID
	) begin

	set @Result = 200101
	RAISERROR ('Invalid job id %d in procedure %s.  Error: %d', 16, 1, @WODID, @ProcName, @Error)
	rollback tran @ProcName
	return
end

declare
	@Machine varchar(10)

select
	@Machine = woh.MachineCode
from
	dbo.WorkOrderDetails wod
	join dbo.WorkOrderHeaders woh
		on woh.WorkOrderNumber = wod.WorkOrderNumber
where
	wod.RowID = @WODID
---	</ArgumentValidation>

--- <Body>
/*	If this box has been deleted, recreate it.  */
if	not exists
	(	select
			*
		from
			dbo.object o
		where
			o.serial = @PreObjectSerial
	) begin

	--- <Insert rows="1">
	set	@TableName = 'dbo.object'
	
		insert 
			dbo.object
		(	serial
		,	part
		,	location
		,	last_date
		,	unit_measure
		,	operator
		,	status
		,	quantity
		,	plant
		,	std_quantity
		,	last_time
		,	user_defined_status
		,	type
		,	po_number 
		)
		select
			woo.Serial
		,	woo.PartCode
		,	location = @Machine
		,	last_date = @TranDT
		,	(	select
					pi.standard_unit
				from
					dbo.part_inventory pi
				where
					pi.part = woo.PartCode
			)
		,	@Operator
		,	'H'
		,	woo.Quantity
		,	(	select
					l.plant
				from
					dbo.location l
				where
					l.code = @Machine
			)
		,	woo.Quantity
		,	last_time = @TranDT
		,	'PRESTOCK'
		,	null
		,	null
		from
			dbo.WorkOrderObjects woo
		where
			woo.Serial = @PreObjectSerial
	
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

/*	Write job complete.  */
/*		Update object status, location, plant, operator, work order, cost, and completion date.  */
--- <Update rows="1">
set	@TableName = 'dbo.object'

update
	o
set 
	status = 'A'
,	user_defined_status = 'Approved'
,	last_date = @TranDT
,	last_time = @TranDT
,	location = @Machine
,	plant = (
			 select
				plant
			 from
				location
			 where
				code = @Machine
			)
,	operator = @Operator
,	workorder = @WODID
,	cost = (
			select
				cost_cum
			from
				dbo.part_standard
			where
				part = o.part
			)
,	std_cost = (
				select
					cost_cum
				from
					dbo.part_standard
				where
					part = o.part
				)
from
	dbo.object o
where
	o.serial = @PreObjectSerial

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
	o.serial = @PreObjectSerial

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
				o2.serial = @PreObjectSerial
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

/*		Create back flush header.  */
--- <Insert rows="1">
set	@TableName = 'dbo.BackflushHeaders'

insert
	dbo.BackflushHeaders
(	TranDT
,	WorkOrderNumber
,	WorkOrderDetailLine
,	MachineCode
,	PartProduced
,	SerialProduced
,	QtyProduced
)
select
	@TranDT
,	wod.WorkOrderNumber
,	wod.Line
,	woh.MachineCode
,	wod.PartCode
,	@PreObjectSerial
,	@QtyRequested
from
	dbo.WorkOrderDetails wod
	join dbo.WorkOrderHeaders woh
		on woh.WorkOrderNumber = wod.WorkOrderNumber
where
	wod.RowID = @WODID

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
	@NewBackflushNumber varchar(50)

set	@NewBackflushNumber =
	(	select
	 		bh.BackflushNumber
	 	from
	 		dbo.BackflushHeaders bh
	 	where
	 		bh.RowID = scope_identity()
	 )

/*		Insert audit_trail.  */
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
,	price
,	operator
,	from_loc
,	to_loc
,	on_hand
,	lot
,	weight
,	status
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
,	gl_account
,	std_cost
,	group_no
,	user_defined_status
,	part_name
,	tare_weight
)
select
	serial = o.serial
,	date_stamp = @TranDT
,	type = 'J'
,	part = o.part
,	quantity = o.quantity
,	remarks = 'Job comp'
,	price = 0
,	operator = o.operator
,	from_loc = o.location
,	to_loc = o.location
,	on_hand = coalesce(po.on_hand, 0) +
		case	when o.status = 'A' then o.std_quantity
				else 0
		end
,	lot = o.lot
,	weight = o.weight
,	status = o.status
,	unit = o.unit_measure
,	workorder = o.workorder
,	std_quantity = o.std_quantity
,	cost = o.cost
,	custom1 = o.custom1
,	custom2 = o.custom2
,	custom3 = o.custom3
,	custom4 = o.custom4
,	custom5 = o.custom5
,	plant = o.plant
,	notes = ''
,	gl_account = ''
,	std_cost = o.cost
,	group_no = right(@NewBackflushNumber, 10)
,	user_defined_status = o.user_defined_status
,	part_name = o.name
,	tare_weight = o.tare_weight
from
	dbo.object o
	left join dbo.part_online po
		on po.part = o.part
	join dbo.part p
		on p.part = o.part
where
	o.serial = @PreObjectSerial

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

/*	Perform back flush.  */
execute @ProcReturn = dbo.usp_MES_Backflush
	@Operator = @Operator
,	@BackflushNumber = @NewBackflushNumber
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set @Error = @@Error
if @ProcResult != 0 
	begin
		set @Result = 999999
		raiserror ('An error result was returned from the procedure %s', 16, 1, 'ProdControl_BackFlush')
		rollback tran @ProcName
		return	@Result
	end
if @ProcReturn != 0 
	begin
		set @Result = 999999
		raiserror ('An error was returned from the procedure %s', 16, 1, 'ProdControl_BackFlush')
		rollback tran @ProcName
		return	@Result
	end
if @Error != 0 
	begin
		set @Result = 999999
		raiserror ('An error occurred during the execution of the procedure %s', 16, 1, 'ProdControl_BackFlush')
		rollback tran @ProcName
		return	@Result
	end

/*	Update Work Order.  */
--- <Update rows="1">
set	@TableName = 'dbo.WorkOrderObjects'

update
	woo
set 
	Status = dbo.udf_StatusValue('dbo.WorkOrderObjects', 'Completed')
,	CompletionDT = @TranDT
,	BackflushNumber = @NewBackflushNumber
,	UndoBackflushNumber = null
from
	dbo.WorkOrderObjects woo
where
	woo.Serial = @PreObjectSerial

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
set	@TableName = 'dbo.WorkOrderDetails'

update
	wod
set 
	QtyCompleted = QtyCompleted + @QtyRequested
from
	dbo.WorkOrderDetails wod
where
	RowID = @WODID

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
select
	*
from
	dbo.WorkOrderObjects woo
}

Test syntax
{

set statistics io on
set statistics time on
go

declare
	@Operator varchar(10)
,	@PreObjectSerial int

set	@Operator = 'mon'
set	@PreObjectSerial = 1836519

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_MES_JCPreObject
	@Operator = @Operator
,	@PreObjectSerial = @PreObjectSerial
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

select
	*
from
	BackFlushHeaders
where
	SerialProduced = @PreObjectSerial

select
	bd.*
from
	dbo.BackflushDetails bd
	join dbo.BackflushHeaders bh
		on bd.BackflushNumber = bh.BackflushNumber
where
	bh.SerialProduced = @PreObjectSerial

select
	*
from
	audit_trail
where
	date_stamp = @TranDT

select
	*
from
	dbo.audit_trail at
where
	at.date_stamp >= dateadd(n,-1,getdate())
	and at.serial in
	(	select
			SerialConsumed
		from
			dbo.BackflushDetails bd
			join dbo.BackflushHeaders
				on bd.BackflushNumber = dbo.BackflushHeaders.BackflushNumber
		where
			SerialProduced = @PreObjectSerial
	)

select
	*
from
	object
where
	serial = @PreObjectSerial

select
	*
from
	dbo.object o
where
	o.serial in
	(	select
			SerialConsumed
		from
			dbo.BackflushDetails bd
			join dbo.BackflushHeaders
				on bd.BackflushNumber = dbo.BackflushHeaders.BackflushNumber
		where
			SerialProduced = @PreObjectSerial
	)
go

--commit
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

