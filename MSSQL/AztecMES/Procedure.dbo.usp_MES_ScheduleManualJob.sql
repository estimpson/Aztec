
/*
Create procedure fx21st.dbo.usp_MES_ScheduleManualJob
*/

--use fx21st
--go

if	objectproperty(object_id('dbo.usp_MES_ScheduleManualJob'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_MES_ScheduleManualJob
end
go

create procedure dbo.usp_MES_ScheduleManualJob
	@Operator varchar (10)
,	@ManualWorkOrderNumber varchar(50) out
,	@PartCode varchar(25)
,	@MachineCode varchar(25)
,	@BillToCode varchar(10)
,	@BuildQty numeric(20,6)
,	@DueDT datetime
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
/*	Schedule a manual job. */
set	@ManualWorkOrderNumber = null
--- <Call>
set	@CallProcName = 'dbo.usp_Scheduling_ScheduleJob'
execute
	@ProcReturn = dbo.usp_Scheduling_ScheduleJob
	@WorkOrderNumber = @ManualWorkOrderNumber out
,	@Operator = @Operator
,	@MachineCode = @MachineCode
,	@ToolCode = null
,	@ProcessCode = null
,	@PartCode = @PartCode
,	@NewFirmQty = @BuildQty
,	@DueDT = @DueDT
,	@TopPart = null
,	@SalesOrderNo = null
,	@ShipToCode = null
,	@BillToCode = @BillToCode
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
	return
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran @ProcName
	return
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return
end
--- </Call>

--- <Update rows="1">
set	@TableName = 'dbo.WorkOrderHeaders'

update
	woh
set
	Type = dbo.udf_TypeValue('dbo.WorkOrderHeaders', 'Manual')
from
	dbo.WorkOrderHeaders woh
where
	woh.WorkOrderNumber = @ManualWorkOrderNumber

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

--- <Update rows="1">
set	@TableName = 'dbo.WorkOrderDetails'

update
	wod
set
	Type = dbo.udf_TypeValue('dbo.WorkOrderDetails', 'Manual')
from
	dbo.WorkOrderDetails wod
where
	wod.WorkOrderNumber = @ManualWorkOrderNumber

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

}

Test syntax
{

set statistics io on
set statistics time on
go

declare
	@Operator varchar (10)
,	@ManualWorkOrderNumber varchar(50)
,	@PartCode varchar(25)
,	@MachineCode varchar(25)
,	@BillToCode varchar(10)
,	@BuildQty numeric(20,6)
,	@DueDT datetime

set	@Operator = 'mon'
set	@ManualWorkOrderNumber = null
set	@PartCode = 'xyz'
set @MachineCode = '3'
set	@BillToCode = 'ACME'
set	@BuildQty = '50'
set	@DueDT = getdate()

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_MES_ScheduleManualJob
	@Operator = @Operator
,	@ManualWorkOrderNumber = @ManualWorkOrderNumber out
,	@PartCode = @PartCode
,	@MachineCode = @MachineCode
,	@BillToCode = @BillToCode
,	@BuildQty = @BuildQty
,	@DueDT = @DueDT
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

select
	*
from
	dbo.WorkOrderHeaders woh
	join dbo.WorkOrderDetails wod
		on woh.WorkOrderNumber = wod.WorkOrderNumber
where
	woh.WorkOrderNumber = @ManualWorkOrderNumber
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
