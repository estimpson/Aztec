
/*
Create procedure Fx.dbo.usp_InventoryControl_QualityBatch_EndQualityBatch
*/

--use Fx
--go

if	objectproperty(object_id('dbo.usp_InventoryControl_QualityBatch_EndQualityBatch'), 'IsProcedure') = 1 begin
	drop procedure dbo.usp_InventoryControl_QualityBatch_EndQualityBatch
end
go

create procedure dbo.usp_InventoryControl_QualityBatch_EndQualityBatch
	@User varchar(10)
,	@QualityBatchNumber varchar(50)
,	@TranDT datetime = null out
,	@Result integer = null out
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
/*	Loop through all quality batch objects and write qualtity transactions. */
declare
	qualityBatchObjects cursor local forward_only for
select
	icqbo.Serial
from
	dbo.InventoryControl_QualityBatchObjects icqbo
where
	icqbo.QualityBatchNumber = @QualityBatchNumber

open
	qualityBatchObjects

while
	1 = 1 begin
	
	declare
		@serial int
	
	fetch
		qualityBatchObjects
	into
		@serial
	
	if	@@FETCH_STATUS != 0 begin
		break
	end
	
	/*	Write quality transactions. */
	--- <Call>	
	set	@CallProcName = 'dbo.usp_InventoryControl_QualityBatch_WriteObjectStatus'
	execute
		@ProcReturn = dbo.usp_InventoryControl_QualityBatch_WriteObjectStatus
			@User = @User
		,	@QualityBatchNumber = @QualityBatchNumber
		,	@Serial = @serial
		,	@DeleteScrapped = null -- Leave it to parameters.
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

/*	Update the quality batch header. */
--- <Call>	
set	@CallProcName = '[callProc]'
execute
	@ProcReturn = dbo.usp_InventoryControl_QualityBatch_UpdateHeader 
		@QualityBatchNumber = @QualityBatchNumber
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

/*	End the quality batch. */
--- <Update rows="1">
set	@TableName = 'dbo.InventoryControl_QualityBatchHeaders'

update
	icqbh
set
	Status = 2
,	SortEndDT = @TranDT
from
	dbo.InventoryControl_QualityBatchHeaders icqbh
where
	icqbh.QualityBatchNumber = @QualityBatchNumber

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

---	<CloseTran AutoCommit=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
---	</CloseTran AutoCommit=Yes>

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
	@ProcReturn = dbo.usp_InventoryControl_QualityBatch_EndQualityBatch
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
go

