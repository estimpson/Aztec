SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_MES_CorrectPreObject]
	@Operator varchar (10)
,	@WODID int
,	@QtyBox int
,	@PackageCode varchar(25)
,	@LotNumber varchar(20)
,	@CorrectionSerial int
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
declare	@Part varchar (25)
select
	@Part =	PartCode
from
	dbo.WorkOrderDetails wod
where
	RowID = @WODID

if	@@RowCount != 1 or @@Error != 0 begin
	
	set	@Result = 200101
	RAISERROR ('Invalid job id %d in procedure %s.  Error: %d', 16, 1, @WODID, @ProcName, @Error)
	rollback tran @ProcName
	return
end

/*	Pre-object must be valid:  */
if	exists
	(	select
			*
		from
			dbo.WorkOrderObjects woo
		where
			woo.Serial = @CorrectionSerial
			and Status = dbo.udf_StatusValue('dbo.WorkOrderObjects', 'Completed')
	) begin
	
	RAISERROR ('Invalid pre-object.  Serial %d was already completed.  Error: %d', 16, 1, @WODID, @ProcName, @CorrectionSerial)
	rollback tran @ProcName
	return
end
if	exists
	(	select
			*
		from
			dbo.WorkOrderObjects woo
		where
			woo.Serial = @CorrectionSerial
			and Status = dbo.udf_StatusValue('dbo.WorkOrderObjects', 'Deleted')
	) begin
	
	RAISERROR ('Invalid pre-object.  Serial %d was deleted.  Error: %d', 16, 1, @WODID, @ProcName, @CorrectionSerial)
	rollback tran @ProcName
	return
end

/*	Part valid:  */
if	not exists
	(	select	1
		from	part
		where	part = @Part) begin

	set	@Result = 70001
	RAISERROR ('Invalid part %s for job id %d in procedure %s.  Error: %d', 16, 1, @Part, @WODID, @ProcName, @Error)
	rollback tran @ProcName
	return
end
---	</ArgumentValidation>

--- <Body>
declare
	@Status char(1)
,	@UserStatus varchar(10)
,	@ObjectType char(1)
,	@TranType char(1)
,	@Remark varchar(10)
,	@Notes varchar(50)
,	@AssemblyPreObjectLocation varchar(10)

set	@Status = 'H'
set	@UserStatus = 'PRESTOCK'
set	@ObjectType = null
set	@TranType = 'P'
set	@Remark = 'PRE-OBJECT'
set	@Notes = 'Pre-object.'
set	@AssemblyPreObjectLocation = 'PRE-OBJECT'

/*	Correct object(s). */
--- <Update rows="1">
set	@TableName = 'dbo.object'

update
	o
set
	quantity = @QtyBox
,	std_quantity = @QtyBox
,	package_type = @PackageCode
,	last_date = @TranDT
,	last_time = @TranDT
,	operator = @Operator
,	lot = @LotNumber
from
	dbo.object o
where
	o.serial = @CorrectionSerial

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

/*	Correct audit trail.  */
--- <Update rows="1">
set	@TableName = 'dbo.audit_trail'

update
	at
set
	quantity = @QtyBox
,	std_quantity = @QtyBox
,	package_type = @PackageCode
,	date_stamp = @TranDT
,	operator = @Operator
,	lot = @LotNumber
from
	dbo.audit_trail at
where
	at.serial = @CorrectionSerial

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
set	QtyLabelled = QtyLabelled + (@QtyBox - woo.Quantity)
from
	dbo.WorkOrderDetails wod
	join dbo.WorkOrderObjects woo
		on woo.Serial = @CorrectionSerial
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

/*	Correct work order object.  */
--- <Update rows="1">
set	@TableName = 'dbo.WorkOrderObjects'

update
	woo
set
	OperatorCode = @Operator
,	Quantity = @QtyBox
,	PackageType = @PackageCode
,	LotNumber = @LotNumber
from
	dbo.WorkOrderObjects woo
where
	woo.Serial = @CorrectionSerial

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
	@Operator varchar (10)
,	@WODID int
,	@QtyToLabel numeric(20,6)
,	@QtyBox int
,	@PackageCode varchar(25)
,	@CorrectionSerial int
,	@Boxes int

set	@Operator = 'mon'
set @WODID = 189
set @QtyToLabel = 10
set @QtyBox = 8
set @PackageCode = 'NUS-22'
set @Boxes = 2

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_MES_CorrectPreObject
	@Operator = @Operator
,	@WODID = @WODID
,	@QtyToLabel = @QtyToLabel
,	@QtyBox = @QtyBox
,	@PackageCode = @PackageCode
,	@CorrectionSerial = @CorrectionSerial out
,	@Boxes = @Boxes out
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@CorrectionSerial, @Boxes, @Error, @ProcReturn, @TranDT, @ProcResult

select
	o.*
from
	dbo.object o
where
	o.serial between @CorrectionSerial and @CorrectionSerial + @Boxes - 1

select
	at.*
from
	dbo.audit_trail at
where
	at.serial between @CorrectionSerial and @CorrectionSerial + @Boxes - 1

select
	p.next_serial
from
	dbo.parameters p

exec dbo.usp_MES_GetJobList
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
GO
