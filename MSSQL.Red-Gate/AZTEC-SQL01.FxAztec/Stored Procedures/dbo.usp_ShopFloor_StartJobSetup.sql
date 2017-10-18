SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ShopFloor_StartJobSetup]
	@Operator varchar(5)
,	@WorkOrderNumber varchar(50)
,	@WorkOrderDetailSequence int
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
set	@TranDT = coalesce(@TranDT, @TranDT)
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
/*	Set (create) active job, operator on machine. (ui1) */
--- <Update rows="1">
set	@TableName = 'dbo.MachineState'

update
	dbo.MachineState
set
	Type = dbo.udf_TypeValue('dbo.MachineState', 'Job Setup')
,	OperatorCode = @Operator
,	ActiveWorkOrderNumber = @WorkOrderNumber
,	ActiveWorkOrderDetailSequence = @WorkOrderDetailSequence
where
	MachineCode = (select MachineCode from dbo.WorkOrderHeaders where WorkOrderNumber = @WorkOrderNumber)

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
	set	@TableName = 'dbo.MachineState'
	
	insert
		dbo.MachineState
	(
		MachineCode
	,	Status
	,	Type
	,	OperatorCode
	,	ActiveWorkOrderNumber
	,	ActiveWorkOrderDetailSequence
	)
	select
		MachineCode = woh.MachineCode
	,	Status = dbo.udf_StatusValue('dbo.MachineState', 'New')
	,	Type = dbo.udf_TypeValue('dbo.MachineState', 'Job Setup')
	,	OperatorCode = @Operator
	,	ActiveWorkOrderNumber = @WorkOrderNumber
	,	ActiveWorkOrderDetailSequence = @WorkOrderDetailSequence
	from
		dbo.WorkOrderHeaders woh
	where
		woh.WorkOrderNumber = @WorkOrderNumber
	
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
/*	Resequence job to sequence 0 on machine. */
declare
	@PriorSequence int

set
	@PriorSequence = (select Sequence from dbo.WorkOrderHeaders where WorkOrderNumber = @WorkOrderNumber)

/*		Set job sequence to 0. (u1) */
--- <Update rows="1">
set	@TableName = 'dbo.WorkOrderHeaders'

update
	dbo.WorkOrderHeaders
set
	Sequence = 0
where
	WorkOrderNumber = @WorkOrderNumber

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

/*		Move any later jobs up 1 sequence. (u*) */
--- <Update rows="*">
set	@TableName = 'dbo.WorkOrderHeaders'

update
	dbo.WorkOrderHeaders
set
	Sequence = Sequence - 1
where
	MachineCode = (select MachineCode from dbo.WorkOrderHeaders where WorkOrderNumber = @WorkOrderNumber)
	and
		Sequence > @PriorSequence

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
/*	Resequence job detail to "next" on job. */
/*		Get the "next" job detail sequence. */
declare
	@NextJobDetailSequence int

set
	@NextJobDetailSequence = coalesce
	(
		(select min(Sequence) from dbo.WorkOrderDetails where WorkOrderNumber = @WorkOrderNumber and Status = dbo.udf_StatusValue('dbo.WorkOrderDetails', 'New'))
	,	1
	)
	
/*		Set job detail sequence to "next". (u1+) */
--- <Update rows="1+">
set	@TableName = 'dbo.WorkOrderDetails'

update
	dbo.WorkOrderDetails
set
	Sequence = @NextJobDetailSequence
where
	WorkOrderNumber = @WorkOrderNumber
	and
		Sequence = @WorkOrderDetailSequence

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount <= 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating into %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update>

/*		Move any later jobs details up 1 sequence. (u*) */
--- <Update rows="*">
set	@TableName = 'dbo.WorkOrderDetails'

update
	dbo.WorkOrderDetails
set
	Sequence = Sequence - 1
where
	WorkOrderNumber = @WorkOrderNumber
	and
		Sequence > @WorkOrderDetailSequence

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

/*	Create down time record to measure machine setup time.*/
--- <Insert rows="1">
set	@TableName = 'dbo.DownTimeEntries'

insert
	dbo.DownTimeEntries
(
	Status
,	Type
,	Machine
,	DownTimeCode
,	DownTimeHours
,	Notes
,	Operator
,	ShiftDT
,	WorkOrderNumber
,	WorkOrderDetailSequence
,	BeginDownTimeDT
,	EndDownTimeDT
)
select
	Status = dbo.udf_StatusValue('dbo.DownTimeEntries', 'New')
,	Type = dbo.udf_TypeValue('dbo.DownTimeEntries', 'Wizard')
,	Machine = woh.MachineCode
,	DownTimeCode = 'SET MACH.'
,	DownTimeHours = null
,	Notes = null
,	Operator = @Operator
,	ShiftDT = null
,	WorkOrderNumber = @WorkOrderNumber
,	WorkOrderDetailSequence = @WorkOrderDetailSequence
,	BeginDownTimeDT = @TranDT
,	EndDownTimeDT = null
from
	dbo.WorkOrderHeaders woh
where
	woh.WorkOrderNumber = @WorkOrderNumber

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

/*	Set job status to "Setup Machine." */
--- <Update rows="1">
set	@TableName = 'dbo.WorkOrderHeaders'

update
	woh
set
	Status = dbo.udf_StatusValue('dbo.WorkOrderDetails', 'Setup Machine')
from
	dbo.WorkOrderHeaders woh
where
	WorkOrderNumber = @WorkOrderNumber

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


/*	Set job detail status to "Setup Machine."*/
--- <Update rows="1+">
set	@TableName = 'dbo.WorkOrderDetails'

update
	wod
set
	Status = dbo.udf_StatusValue('dbo.WorkOrderDetails', 'Setup Machine')
from
	dbo.WorkOrderDetails wod
where
	WorkOrderNumber = @WorkOrderNumber
	and
		Sequence = @WorkOrderDetailSequence

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount <= 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1 or more.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
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
	@Param1 [scalar_data_type]

set	@Param1 = [test_value]

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_ShopFloor_StartJobSetup
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
