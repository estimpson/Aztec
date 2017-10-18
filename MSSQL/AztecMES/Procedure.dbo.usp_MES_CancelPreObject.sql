
/*
Create procedure fx21stPilot.dbo.usp_MES_CancelPreObject

Description:
Closes the object corresponding to a PreObject after label printing.
*/

--use fx21stPilot
--go

if	objectproperty(object_id('dbo.usp_MES_CancelPreObject'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_MES_CancelPreObject
end
go

create procedure dbo.usp_MES_CancelPreObject
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
/*	If this box exists, delete it.  */
if	exists
	(	select
			*
		from
			dbo.object o
		where
			o.serial = @PreObjectSerial
	) begin

	--- <Delete rows="1">
	set	@TableName = '[tableName]'
	
	delete
		o
	from
		dbo.object o
	where
		serial = @PreObjectSerial
	
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


/*	Mark pre-object history as deleted.  */
--- <Update rows="1">
set	@TableName = 'dbo.WorkOrderObjects'

update
	woo
set
	Status = dbo.udf_StatusValue('dbo.WorkOrderObjects', 'Deleted')
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

/*	Update quantity printed.  */
--- <Update rows="1">
set	@TableName = 'dbo.WorkOrderDetails'

update
	wod
set	QtyLabelled = QtyLabelled - @QtyRequested
from
	dbo.WorkOrderDetails wod
where
	wod.RowID = @WODID

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
	@ProcReturn = dbo.usp_MES_CancelPreObject
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

