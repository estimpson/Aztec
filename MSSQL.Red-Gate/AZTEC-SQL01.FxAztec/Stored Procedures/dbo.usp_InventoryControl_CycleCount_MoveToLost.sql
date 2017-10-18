SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_InventoryControl_CycleCount_MoveToLost]
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
/*	Get the global parameter for delete lost days. */
declare
	@HoldLostDays numeric(20,6)

select
	@HoldLostDays = coalesce
    (	(	select
				convert(numeric(20,6), g.Value)
			from
				Fx.Globals g
			where
				g.Name = 'CycleCount.HoldLostDays'
		)
	,	-1.0
	)

declare
	LostObjects cursor local for
select
	iccco.Serial
,	iccco.OriginalLocation
from
	dbo.InventoryControl_CycleCountObjects iccco
	join dbo.object o
		on o.serial = iccco.Serial
where
	iccco.CycleCountNumber = @CycleCountNumber
	and iccco.Status = -1

open
	LostObjects

while
	1 = 1 begin
	
	declare
		@serial int
	,	@originalLocation varchar(10)
	
	fetch
		LostObjects
	into
		@serial
	,	@originalLocation
	
	if	@@FETCH_STATUS != 0 begin
		break
	end
	
	/*	Inventory lost. */
	declare
		@note varchar(254)
	
	set	@note = 'Transferred from ' + @originalLocation + ' to lost'
	
	--- <Call>	
	set	@CallProcName = 'dbo.usp_InventoryControl_Transfer'
	execute
		@ProcReturn = dbo.usp_InventoryControl_Transfer
		    @Operator = @User
		,   @Serial = @serial
		,   @LocationCode = 'LOST'
		,   @Notes = @note
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

	/*	Delete lost if specified period is 0.0. */
	if	@HoldLostDays = 0.0 begin
    
		--- <Call>	
		set	@CallProcName = 'dbo.usp_InventoryControl_Delete'
		execute
			@ProcReturn = dbo.usp_InventoryControl_Delete
				@Operator = @User
			,	@Serial = @serial
			,	@Notes = 'Deleted in cycle count'
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
end

close
	LostObjects

deallocate
	LostObjects
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
,	@Serial int = null

set	@User = 'mon'
set	@CycleCountNumber = '0'
set	@Serial = '0'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_InventoryControl_CycleCount_MoveToLost
	@User = @User
,	@CycleCountNumber = @CycleCountNumber
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
