SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_InventoryControl_CycleCount_End]
	@User varchar(10)
,	@CycleCountNumber varchar(50)
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
/*	End cycle count. */
--- <Update rows="1">
set	@TableName = 'dbo.InventoryControl_CycleCountHeaders'

update
	iccch
set
	CountEndDT = @TranDT
,	Status = 2
from
	dbo.InventoryControl_CycleCountHeaders iccch
where
	iccch.CycleCountNumber = @CycleCountNumber
	and iccch.Status = 1

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

/*	Recover objects. */
--- <Call>	
set	@CallProcName = 'dbo.usp_InventoryControl_CycleCount_RecoverObjects'
execute
	@ProcReturn = dbo.usp_InventoryControl_CycleCount_RecoverObjects
	    @User = @User
	,   @CycleCountNumber = @CycleCountNumber
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


/*	Correct quantities. */
--- <Call>	
set	@CallProcName = 'dbo.usp_InventoryControl_CycleCount_CorrectObjectQuantities'
execute
	@ProcReturn = dbo.usp_InventoryControl_CycleCount_CorrectObjectQuantities
	    @User = @User
	,   @CycleCountNumber = @CycleCountNumber
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

/*	Correct locations. */
--- <Call>	
set	@CallProcName = 'dbo.usp_InventoryControl_CycleCount_CorrectObjectLocations'
execute
	@ProcReturn = dbo.usp_InventoryControl_CycleCount_CorrectObjectLocations 
	    @User = @User
	,   @CycleCountNumber = @CycleCountNumber
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

/*	Move to lost. */
--- <Call>	
set	@CallProcName = 'dbo.usp_InventoryControl_CycleCount_MoveToLost'
execute
	@ProcReturn = dbo.usp_InventoryControl_CycleCount_MoveToLost 
	    @User = @User
	,   @CycleCountNumber = @CycleCountNumber
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

/*	Mark counted. */
--- <Call>	
set	@CallProcName = 'dbo.usp_InventoryControl_CycleCount_CountObjects'
execute
	@ProcReturn = dbo.usp_InventoryControl_CycleCount_CountObjects 
	    @User = @User
	,   @CycleCountNumber = @CycleCountNumber
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

/*	Record the date records were committed. */
--- <Update rows="*">
set	@TableName = 'dbo.InventoryControl_CycleCountObjects'

update
	iccco
set	RowCommittedDT = iccch.CountEndDT
from
	dbo.InventoryControl_CycleCountObjects iccco
	join dbo.InventoryControl_CycleCountHeaders iccch
		on iccch.CycleCountNumber = iccco.CycleCountNumber
where
	iccch.CycleCountNumber = @CycleCountNumber
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
--- </Update>

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
,	@CycleCountNumber varchar(50)

set	@User = 'EES'
set	@CycleCountNumber = 'CC_000000010'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_InventoryControl_CycleCount_End
	@User = @User
,	@CycleCountNumber = @CycleCountNumber
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

select
	*
from
	dbo.audit_trail at
where
	at.date_stamp = @TranDT

select
	*
from
	dbo.object o
where
	o.serial in
	(	select
			at.serial
		from
			dbo.audit_trail at
		where
			at.date_stamp = @TranDT
	)
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
