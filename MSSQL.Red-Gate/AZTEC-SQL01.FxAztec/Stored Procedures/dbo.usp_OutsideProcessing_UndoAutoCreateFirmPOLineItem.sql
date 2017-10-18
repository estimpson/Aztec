SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_OutsideProcessing_UndoAutoCreateFirmPOLineItem]
	@User varchar(10)
,	@VendorShipFrom varchar(20)
,	@RawPartCode varchar(25)
,	@RawPartStandardQty numeric(20,6)
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

--- <Tran Required=Yes UndoAutocreate=Yes TranDTParm=Yes>
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
--- <Update rows="*">
declare
	@expectedRows int

set	@expectedRows =
	(	select
			count(*)
		from
			dbo.OutsideProcessing_BlanketPOs opbpo
			cross join dbo.parameters p
		where
			opbpo.InPartCode = @RawPartCode
			and coalesce(opbpo.VendorShipFrom, @VendorShipFrom, 'N/A') = coalesce(@VendorShipFrom, 'N/A')
	)

set	@TableName = 'dbo.po_detail'

update
	pd
set
	quantity = quantity - dbo.udf_GetQtyFromStdQty(opbpo.OutPartCode, @RawPartStandardQty / opbpo.BOMQty, opbpo.ReceivingUnit)
,	balance = balance - dbo.udf_GetQtyFromStdQty(opbpo.OutPartCode, @RawPartStandardQty / opbpo.BOMQty, opbpo.ReceivingUnit)
,	standard_qty = pd.standard_qty - @RawPartStandardQty / opbpo.BOMQty
from
	dbo.po_detail pd
	join dbo.OutsideProcessing_BlanketPOs opbpo
		on opbpo.PONumber = pd.po_number
		and opbpo.PONumber = coalesce(opbpo.DefaultPO, opbpo.PONumber)
		and opbpo.InPartCode = @RawPartCode
		and coalesce(opbpo.VendorShipFrom, @VendorShipFrom, 'N/A') = coalesce(@VendorShipFrom, 'N/A')
where
	pd.date_due = FT.fn_TruncDate('day', @TranDT + opbpo.ProcessDays)
	and pd.row_id =
	(	select
			max(row_id)
		from
			dbo.po_detail pd2
		where
			pd2.po_number = pd.po_number
			and pd2.part_number = pd.part_number
			and pd2.date_due = pd.date_due
	)

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

/*	Delete depleted rows. */
--- <Delete rows="*">
set	@TableName = 'dbo.po_detail'

delete
	pd
from
	dbo.po_detail pd
	join dbo.OutsideProcessing_BlanketPOs opbpo
		on opbpo.PONumber = pd.po_number
		and opbpo.InPartCode = @RawPartCode
		and coalesce(opbpo.VendorShipFrom, @VendorShipFrom, 'N/A') = coalesce(@VendorShipFrom, 'N/A')
where
	pd.date_due = FT.fn_TruncDate('day', @TranDT + opbpo.ProcessDays)
	and pd.row_id =
	(	select
			max(row_id)
		from
			dbo.po_detail pd2
		where
			pd2.po_number = pd.po_number
			and pd2.part_number = pd.part_number
			and pd2.date_due = pd.date_due
	)
	and pd.balance <= 0
	and pd.received = 0

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error deleting from table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Insert>

--- <Insert rows="*">
set	@TableName = 'dbo.po_detail'

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
--- </Insert>
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
	@User varchar(10)
,	@VendorShipFrom varchar(10)
,	@RawPartCode varchar(10)
,	@RawPartStandardQty numeric(20,6)

set	@User = 'mon'
set @VendorShipFrom = null
set @RawPartCode = '2476-OP5'
set @RawPartStandardQty = 1000

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = dbo.usp_OutsideProcessing_UndoAutoCreateFirmPOLineItem
	@User = @User
,	@VendorShipFrom = @VendorShipFrom
,	@RawPartCode = @RawPartCode
,	@RawPartStandardQty = @RawPartStandardQty
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

select
	*
from
	dbo.po_detail pd
where
	pd.po_number = 270
	and pd.quantity > 0

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
