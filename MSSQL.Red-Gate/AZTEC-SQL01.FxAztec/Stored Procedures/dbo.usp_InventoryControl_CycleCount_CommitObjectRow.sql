SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[usp_InventoryControl_CycleCount_CommitObjectRow]
	@User varchar(10)
,	@CycleCountNumber varchar(50)
,	@SerialNumber int
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
/*	Get the status and type of the uncommitted row for the specified serial.*/
declare
	@ccoStatus int
,	@ccoType int
,	@ccoOriginalQty numeric(20,6)
,	@ccoCorrectedQty numeric(20,6)
,	@ccoOriginalLocation varchar(10)
,	@ccoCorrectedLocation varchar(10)

--- <Select rows="1">
set	@TableName = 'dbo.InventoryControl_CycleCountObjects'

select
	@ccoStatus = iccco.Status
,	@ccoType = iccco.Type
,	@ccoOriginalQty = iccco.OriginalQuantity
,	@ccoCorrectedQty = iccco.CorrectedQuantity
,	@ccoOriginalLocation = iccco.OriginalLocation
,	@ccoCorrectedLocation = iccco.CorrectedLocation
from
	dbo.InventoryControl_CycleCountObjects iccco
where
	iccco.CycleCountNumber = @CycleCountNumber
	and iccco.Serial = @SerialNumber
	and iccco.RowCommittedDT is null

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error selecting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	set	@Result = 999999
	RAISERROR ('Error selecting from table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
	rollback tran @ProcName
	return
end
--- </Select>

/*	Take appropriate action depending on status / type... */

/*		... Recover object. */
if	@ccoStatus > 0 and
	@ccoType = 1 begin

	/*	Inventory correction. */
	declare
		@recoeveryNote varchar(254)
	
	set	@recoeveryNote = 'Object recovered from audit trail.'
	
	--- <Call>	
	set	@CallProcName = 'dbo.usp_InventoryControl_Correct'
	execute
		@ProcReturn = dbo.usp_InventoryControl_ManualAdd
		    @Operator = @User
		,   @Serial = @SerialNumber
		,   @Notes = @recoeveryNote
		,   @TranDT = @TranDT out
		,   @Result = @ProcResult out
	
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
/*		... Correct qty. */
else if
	@ccoStatus > 0
	and @ccoCorrectedQty is not null
	and @ccoCorrectedQty != @ccoOriginalQty begin

	/*	Inventory correction. */
	declare
		@qtyCorrectNote varchar(254)
	
	set	@qtyCorrectNote = 'Corrected from ' + convert(varchar, @ccoOriginalQty) + ' to ' + convert(varchar, @ccoCorrectedQty)
	
	--- <Call>	
	set	@CallProcName = 'dbo.usp_InventoryControl_Correct'
	execute
		@ProcReturn = dbo.usp_InventoryControl_Correct
		    @Operator = @User
		,   @Serial = @SerialNumber
		,   @CorrectionQuantity = @ccoCorrectedQty
		,   @Notes = @qtyCorrectNote
		,   @TranDT = @TranDT out
		,   @Result = @ProcResult out
	
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

/*		... Correct location. */
else if
	@ccoStatus > 0
	and @ccoCorrectedLocation is not null
	and @ccoCorrectedLocation != @ccoOriginalLocation begin

	/*	Inventory correction. */
	declare
		@locationCorrectNote varchar(254)
	
	set	@locationCorrectNote = 'Transferred from ' + @ccoOriginalLocation + ' to ' + @ccoCorrectedLocation
	
	--- <Call>	
	set	@CallProcName = 'dbo.usp_InventoryControl_Transfer'
	execute
		@ProcReturn = dbo.usp_InventoryControl_Transfer
		    @Operator = @User
		,   @Serial = @SerialNumber
		,   @LocationCode = @ccoCorrectedLocation
		,   @Notes = @locationCorrectNote
		,   @TranDT = @TranDT out
		,   @Result = @ProcResult out
	
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

/*	Mark object as counted... */
if	@ccoStatus > 0 begin

	/*	Inventory counted. */
	declare
		@countedNote varchar(254)
	
	set	@countedNote = 'Object counted during cycle count ' + @CycleCountNumber + '.'

	--- <Call>	
	set	@CallProcName = 'dbo.usp_InventoryControl_Correct'
	execute
		@ProcReturn = dbo.usp_InventoryControl_CountObject
		    @Operator = @User
		,   @Serial = @SerialNumber
		,	@CycleCountNumber = @CycleCountNumber
		,   @Notes = @countedNote
		,   @TranDT = @TranDT out
		,   @Result = @ProcResult out
	
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

/*	Mark record as committed. */
--- <Update rows="1">
set	@TableName = 'dbo.InventoryControl_CycleCountObjects'

update
	iccco
set
	RowCommittedDT = @TranDT
from
	dbo.InventoryControl_CycleCountObjects iccco
where
	iccco.Serial = @SerialNumber
	and iccco.CycleCountNumber = @CycleCountNumber
	and iccco.RowCommittedDT is null

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
	@User varchar(10) = 'EES'
,	@CycleCountNumber varchar(50) = 'CC_000010008'
,	@SerialNumber int = 1567307

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_InventoryControl_CycleCount_CommitObjectRow
	@User = @User
,	@CycleCountNumber = @CycleCountNumber
,	@SerialNumber = @SerialNumber
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
