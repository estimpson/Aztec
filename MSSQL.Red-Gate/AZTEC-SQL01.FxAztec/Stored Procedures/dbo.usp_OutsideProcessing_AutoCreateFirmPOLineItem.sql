SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[usp_OutsideProcessing_AutoCreateFirmPOLineItem]
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
--- <Update rows="*">
declare
	@expectedRows int

set	@expectedRows =
	(	select
			count(*)
		from
			dbo.OutsideProcessing_BlanketPOs opbpo
			cross join dbo.parameters p -- To ensure that the number of rows agrees with insert.
		where
			opbpo.InPartCode = @RawPartCode
			and coalesce(opbpo.VendorShipFrom, @VendorShipFrom, 'N/A') = coalesce(@VendorShipFrom, 'N/A')
			and opbpo.VendorCode = coalesce(opbpo.DefaultVendor, opbpo.VendorCode)
			and opbpo.PONumber = coalesce(opbpo.DefaultPO, opbpo.PONumber)
	)

set	@TableName = 'dbo.po_detail'

update
	pd
set
	quantity = quantity + dbo.udf_GetQtyFromStdQty(opbpo.OutPartCode, @RawPartStandardQty / opbpo.BOMQty, opbpo.ReceivingUnit)
,	balance = balance + dbo.udf_GetQtyFromStdQty(opbpo.OutPartCode, @RawPartStandardQty / opbpo.BOMQty, opbpo.ReceivingUnit)
,	standard_qty = pd.standard_qty + @RawPartStandardQty / opbpo.BOMQty
from
	dbo.po_detail pd
	join dbo.OutsideProcessing_BlanketPOs opbpo
		on opbpo.PONumber = pd.po_number
		and opbpo.InPartCode = @RawPartCode
		and coalesce(opbpo.VendorShipFrom, @VendorShipFrom, 'N/A') = coalesce(@VendorShipFrom, 'N/A')
		and opbpo.VendorCode = coalesce(opbpo.DefaultVendor, opbpo.VendorCode)
		and opbpo.PONumber = coalesce(opbpo.DefaultPO, opbpo.PONumber)
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
if	@RowCount != @expectedRows begin
	--- <Insert rows="*">
	set	@TableName = 'dbo.po_detail'
	
	insert
		dbo.po_detail
	(	po_number
	,	vendor_code
	,	part_number
	,	description
	,	unit_of_measure
	,	date_due
	,	status
	,	type
	,	account_code
	,	quantity
	,	received
	,	balance
	,	price
	,	alternate_price
	,	row_id
	,	release_no
	,	ship_to_destination
	,	terms
	,	week_no
	,	plant
	,	standard_qty
	,	ship_type
	)
	select
		po_number = opbpo.PONumber
	,	vendor_code = opbpo.VendorCode
	,	part_number = opbpo.OutPartCode
	,	description = opbpo.OutPartDescription
	,	unit_of_measure = opbpo.ReceivingUnit
	,	date_due = FT.fn_TruncDate('day', @TranDT + opbpo.ProcessDays)
	,	status = 'A'
	,	type = 'B'
	,	account_code = opbpo.APAccountCode
	,	quantity = dbo.udf_GetQtyFromStdQty(opbpo.OutPartCode, @RawPartStandardQty / opbpo.BOMQty, opbpo.ReceivingUnit)
	,	received = 0
	,	balance = dbo.udf_GetQtyFromStdQty(opbpo.OutPartCode, @RawPartStandardQty / opbpo.BOMQty, opbpo.ReceivingUnit)
	,	price = opbpo.Price
	,	alternate_price = opbpo.Price
	,	row_id = coalesce((select max(row_id) + 1 from dbo.po_detail pd where pd.po_number = opbpo.PONumber), 1)
	,	release_no = opbpo.NextRelease
	,	ship_to_destination = opbpo.DeliveryShipTo
	,	terms = opbpo.Terms
	,	week_no = datediff(week, p.fiscal_year_begin, @TranDT + opbpo.ProcessDays)
	,	plant = opbpo.OrderingPlant
	,	standard_qty = @RawPartStandardQty / opbpo.BOMQty
	,	ship_type = opbpo.ShipType
	from
		dbo.OutsideProcessing_BlanketPOs opbpo
		cross join dbo.parameters p
	where
		opbpo.InPartCode = @RawPartCode
		and coalesce(opbpo.VendorShipFrom, @VendorShipFrom, 'N/A') = coalesce(@VendorShipFrom, 'N/A')
		and opbpo.VendorCode = coalesce(opbpo.DefaultVendor, opbpo.VendorCode)
		and opbpo.PONumber = coalesce(opbpo.DefaultPO, opbpo.PONumber)
		and not exists
		(	select
				*
			from
				dbo.po_detail pd2
			where
				pd2.po_number = opbpo.PONumber
				and pd2.part_number = opbpo.OutPartCode
				and pd2.date_due = FT.fn_TruncDate('day', @TranDT + opbpo.ProcessDays)
		)
	
	select
		@Error = @@Error,
		@RowCount = @RowCount + @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	--- </Insert>
	
end
--- </Update>

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
	@ProcReturn = dbo.usp_OutsideProcessing_AutoCreateFirmPOLineItem
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
