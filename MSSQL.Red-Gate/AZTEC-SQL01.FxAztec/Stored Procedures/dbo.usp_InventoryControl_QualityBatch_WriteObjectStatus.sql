SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_InventoryControl_QualityBatch_WriteObjectStatus]
	@User varchar(10)
,	@QualityBatchNumber varchar(50)
,	@Serial int
,	@DeleteScrapped int = null
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
/*	Get parameter that determines if scrap should delete object. */
declare
	@deleteScrappedBit bit

set	@deleteScrappedBit =
		case
			when @DeleteScrapped in (0,1) then @DeleteScrapped
			when coalesce
					(	(	select
								p.delete_scrapped_objects
							from
								dbo.parameters p
						)
					,	'N'
					) = 'Y' then 1
			else 0
		end

/*	Get the state of the object from the quality batch record. */
declare
	@NewStatus varchar(30)
,	@ScrapQuantity numeric(20,6)
,	@Notes varchar(max)

select
	@NewStatus = icqbo.NewStatus
,	@ScrapQuantity = icqbo.ScrapQuantity
,	@Notes = icqbo.Notes
from
	dbo.InventoryControl_QualityBatchObjects icqbo
where
	icqbo.QualityBatchNumber = @QualityBatchNumber
	and icqbo.Serial = @Serial

/*	Perform scrap transaction first.*/
if	@ScrapQuantity > 0 begin
	declare
		@ScrapStatus varchar(30)
	
	select
		@ScrapStatus = uds.display_name
	from
		dbo.user_defined_status uds
	where
		uds.type = 'S'
		and uds.base = 'Y'
	
	--- <Call>	
	set	@CallProcName = 'dbo.usp_InventoryControl_Qualtity '
	exec
		@ProcReturn = dbo.usp_InventoryControl_Qualtity 
			@User = @User
		,	@Serial = @Serial
		,	@NewUserDefinedStatus = @ScrapStatus
		,	@ScrapRejectQuantity = @ScrapQuantity
		,	@DeleteScrapped = @deleteScrappedBit
		,	@DefectReason = null
		,	@Notes = @Notes
		,	@TranDT = @TranDT out
		,	@Result = @Result out
	
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
	
	/*	Clear the quantity to scrap. */
	--- <Update rows="1">
	set	@TableName = 'dbo.InventoryControl_QualityBatchObjects'
	
	update
		icqbo
	set
		ScrapQuantity = null
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
	
end

/*	Perform quality transaction for remainder.*/
declare
	@currentStatus varchar(30)

set	@currentStatus =
		(	select
				o.user_defined_status
			from
				dbo.object o
			where
				o.serial = @Serial
		)

if	@NewStatus is not null
	and @NewStatus != @currentStatus begin -- If @currentStatus is null then object has been deleted.
	
	--- <Call>	
	set	@CallProcName = 'dbo.usp_InventoryControl_Qualtity'

	exec
		@ProcReturn = dbo.usp_InventoryControl_Qualtity
			@User = @User
		,	@Serial = @Serial
		,	@NewUserDefinedStatus = @NewStatus
		,	@Notes = @Notes
		,	@TranDT = @TranDT out
		,	@Result = @Result out
	
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
	@ProcReturn = dbo.usp_InventoryControl_QualityBatch_WriteObjectStatus
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
