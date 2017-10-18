SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_ShopFloor_SetJobTool]
	@Operator varchar(5)
,	@WorkOrderNumber varchar(50)
,	@WorkOrderDetailSequence int
,	@ToolCode varchar(60)
,	@ToolingNote varchar(max)
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
/*	Set current tool on machine. (u1) */
--- <Update rows="1">
set	@TableName = 'dbo.MachineState'

update
	dbo.MachineState
set
	CurrentToolCode = @ToolCode
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
	set	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Update>

/*	Set tool on job. (u1) */
--- <Update rows="1">
set	@TableName = 'dbo.WorkOrderHeaders'

update
	dbo.WorkOrderHeaders
set
	ToolCode = @ToolCode
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

/*	Set end of down time for machine setup. (u1) */
--- <Update rows="1">
set	@TableName = 'dbo.DownTimeEntries'

update
	dbo.DownTimeEntries
set
	Operator = @Operator
,	EndDownTimeDT = @TranDT
,	DownTimeHours = datediff(second, BeginDownTimeDT, @TranDT) / 3600.0
,	Notes = @ToolingNote
where
	WorkOrderNumber = @WorkOrderNumber
	and
		Status = dbo.udf_StatusValue('dbo.DownTimeEntries', 'New')

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

/*	Create down time record to measure material/process setup time. (i1) */
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
,	DownTimeCode = 'SET MAT.'
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

/*	Set job status to "Setup Material" (u1) */
--- <Update rows="1">
set	@TableName = 'dbo.WorkOrderHeaders'

update
	dbo.WorkOrderHeaders
set
	Status = dbo.udf_StatusValue('dbo.WorkOrderHeaders', 'Setup Material')
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

/*	Set job detail status to "Setup Material" (u1+) */
--- <Update rows="1">
set	@TableName = 'dbo.WorkOrderDetails'

update
	dbo.WorkOrderDetails
set
	Status = dbo.udf_StatusValue('dbo.WorkOrderDetails', 'Setup Material')
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
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
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
	@ProcReturn = dbo.usp_ShopFloor_SetJobTool
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
