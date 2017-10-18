
/*
Create procedure fx21st.dbo.usp_MES_AllocateSerial_toJobID
*/

--use fx21st
--go

if	objectproperty(object_id('dbo.usp_MES_AllocateSerial_toJobID'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_MES_AllocateSerial_toJobID
end
go

create procedure dbo.usp_MES_AllocateSerial_toJobID
	@Operator varchar(5)
,	@Serial int
,	@JobID int
,	@QtyBreakout numeric(20,6) = null
,	@BreakoutSerial int = null out
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
--- <Call>	
set	@CallProcName = 'dbo.usp_MES_AllocateSerial'
execute
	@ProcReturn = dbo.usp_MES_AllocateSerial
	@Operator = @Operator
,	@Serial = @Serial
,	@WODID = @JobID
,	@QtyBreakout = @QtyBreakout
,	@BreakoutSerial = @BreakoutSerial out
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

--- </Body>

---	<Return>
if	@TranCount = 0 begin
	commit tran @ProcName
end
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
,	@Serial int
,	@JobID int
,	@QtyBreakout numeric(20,6)
,	@BreakoutSerial int

set	@Operator = 'mon'
set @Serial = 1647645
set @JobID = 418

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_MES_AllocateSerial_toJobID
	@Operator = @Operator
,	@Serial = @Serial
,	@JobID = @JobID
,	@QtyBreakout = @QtyBreakout
,	@BreakoutSerial = @BreakoutSerial out
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

select
	*
from
	dbo.object o
where
	serial = @Serial

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

select
	*
from
	dbo.object o
where
	serial = 1832411
order by
	o.last_date

select
	*
from
	dbo.MES_JobList mjl
where
	PartCode like '1220SWR21%'


update
	dbo.WorkOrderHeaders
set
	MachineCode = '4'
where
	dbo.WorkOrderHeaders.WorkOrderNumber = 'WO_0000000350'
