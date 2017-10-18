SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_OutsideProcessing_AdjustVendorInventory]
	@Operator varchar(5)
,	@VendorLocation varchar(10)
,	@PartCode varchar(25)
,	@AdjustedQty numeric(20,6)
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
/*	Isolate objects for a particular part and vendor location. */
declare 
	@objects table
(	Serial int
,	Qty numeric(20,6)
,	FIFO_DT datetime
)
	
insert into
	@objects
select
	o.serial
,	o.std_quantity
,	o.last_date
from
	dbo.object o
where
	o.part = @PartCode
	and o.location = @VendorLocation
order by
	o.last_date

declare
	@systemQty numeric(20,6)

set @systemQty = coalesce
		(	(	select
				sum(Qty)
			from
				@objects
			)
		,	0
		)

/*	Handle excess quantity found at outside processor: */
if	@AdjustedQty > @systemQty begin
		
	/*	Use the last serial shipped to the outside processor, or the oldest one there to adjust the quantity. */
	declare
		@excessSerial int
		
	select top 1
		@excessSerial = o.Serial
	from
		@objects o
	order by
		o.FIFO_DT
	
	if	@@RowCount = 0 begin
		select top 1
			@excessSerial = at.serial
		from
			dbo.audit_trail at
		where
			at.type = 'O'
			and at.part = @PartCode
			and at.to_loc = @VendorLocation
		order by
			at.date_stamp desc
	end
	declare
		@excessQty numeric(20,6)
	
	set	@excessQty = @AdjustedQty - @systemQty

	set	@CallProcName = 'dbo.usp_OutsideProcessing_NewExcessQty'
	execute
		@ProcReturn = dbo.usp_OutsideProcessing_NewExcessQty
		@Operator = @Operator
	,	@VendorLocation = @VendorLocation
	,	@Serial = @excessSerial
	,	@QtyExcess = @excessQty
	,	@ExcessReason = 'Excess due to receiving backflush.'
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out

	set @Error = @@Error
	if @Error != 0 begin
		set	@Result = 900501
		RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		rollback tran @ProcName
		return @Result
	end
	if @ProcResult != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
	if @ProcReturn != 0 begin
		set	@Result = 900502
		RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		rollback tran @ProcName
		return	@Result
	end
end
/*	Otherwise, handle shortage adjustment. */
else if
	@systemQty > @AdjustedQty begin

	declare
		@shortQty numeric(20,6)
	
	set @shortQty = @systemQty - @AdjustedQty -- The total quantity to adjust.
	
	/*	Loop through inventory and perform shortages. */
	declare Serials cursor local for
	select
		o.Serial
	,	o.Qty
	from
		@objects o
	order by
		o.FIFO_DT
		
	open Serials

	while
		@shortQty > 0 begin
		
		declare
			@shortageSerial int
		,	@objectQty numeric(20,6)
		,	@shortageObjectQty numeric(20,6)
		
		fetch
			Serials
		into
			@shortageSerial
		,	@objectQty
		
		if	@@fetch_Status != 0 begin
			break
		end
		
		set	@shortageObjectQty = case when @objectQty > @shortQty then @shortQty else @objectQty end
		
		-- The quantity to adjust down is greater than the quantiy of this serial
		set	@CallProcName = 'dbo.usp_OutsideProcessing_NewShortageQty'
		execute
			@ProcReturn = dbo.usp_OutsideProcessing_NewShortageQty
			@Operator = @Operator
		,	@VendorLocation = @VendorLocation
		,	@Serial = @shortageSerial
		,	@QtyShortage = @shortageObjectQty
		,	@ShortageReason = 'Shortage during adjustment of vendor inventory.'
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
		
		set @shortQty = @shortQty - @shortageObjectQty -- Remaining quantity left to adjust
	end -- end while statement
	
	-- dispose of cursor
	close
		Serials
	deallocate
		Serials	
end

--- <CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
--- </CloseTran Required=Yes AutoCreate=Yes>
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
	@Operator varchar(5)
,	@VendorLocation varchar(10)
,	@PartCode varchar(25)
,	@AdjustedQty numeric(20,6)

set	@Operator = ''
set @VendorLocation = 'MAR0200'
set	@PartCode = '2904(L)-RAW'
set	@AdjustedQty = 1

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_OutsideProcessing_AdjustVendorInventory
	@Operator = @Operator
,	@VendorLocation = @VendorLocation
,	@PartCode = @PartCode
,	@AdjustedQty = @AdjustedQty
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
