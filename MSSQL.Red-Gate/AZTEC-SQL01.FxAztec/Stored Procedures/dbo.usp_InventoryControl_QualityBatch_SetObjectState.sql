SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_InventoryControl_QualityBatch_SetObjectState]
	@User varchar(10)
,	@QualityBatchNumber varchar(50)
,	@Serial int
,	@NewStatus varchar(30)
,	@ScrapQuantity numeric(20,6)
,	@Notes varchar(max)
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
/*	Set the state of the object. */
--- <Update rows="1">
set	@TableName = 'dbo.InventoryControl_QualityBatchObjects'

update
	icqbo
set
	Status =
		case
			when @ScrapQuantity = (select o.std_quantity from dbo.object o where o.serial = @Serial) then -1
			when (select uds.type from dbo.user_defined_status uds where uds.display_name = @NewStatus) = 'A' and coalesce(@ScrapQuantity, 0) = 0 then 1
			when (select uds.type from dbo.user_defined_status uds where uds.display_name = @NewStatus) = 'A' and @ScrapQuantity > 0 then 2
			when (select uds.type from dbo.user_defined_status uds where uds.display_name = @NewStatus) = 'H' then 4
			else icqbo.Status
		end
,	NewStatus = @NewStatus
,	ScrapQuantity = nullif(@ScrapQuantity, 0)
,	Notes = @Notes
from
	dbo.InventoryControl_QualityBatchObjects icqbo
where
	icqbo.QualityBatchNumber = @QualityBatchNumber
	and icqbo.Serial = @Serial

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

/*	Adjust header. */
--- <Call>	
set	@CallProcName = 'dbo.usp_InventoryControl_QualityBatch_UpdateHeader'
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

--- </Body>

--- <Tran AutoClose=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </Tran>

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
	@User varchar(10)
,	@QualityBatchNumber varchar(50)
,	@Serial int = null

set	@User = 'mon'
set	@QualityBatchNumber = '0'
set	@Serial = '0'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_InventoryControl_QualityBatch_SetObjectState
	@User = @User
,	@QualityBatchNumber = @QualityBatchNumber
,	@Serial = @Serial
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
