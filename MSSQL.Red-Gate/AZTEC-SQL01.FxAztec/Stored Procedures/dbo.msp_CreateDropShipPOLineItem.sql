SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[msp_CreateDropShipPOLineItem]
(	@PONumber integer,
	@Quantity numeric (20,6),
	@Price numeric (20,6),
	@OrderDetailID integer,
	@Result integer = null output )
as
---------------------------------------------------------------------------------------
--	Description:
--	This procedure creates a drop ship PO line item on the specified PO.  If a
--	compatable item is already found on the PO (Same sales order and row id) then
--	the quantity is added to the existing PO line item and the price is updated.
--
--	Parameters:
--	PONumber	The PO Number to add the line item to.
--	Quantity	The amount of an item being purchased.
--	Price		The vendor's price.
--	OrderDetailID	The key to the sales order line item that the PO line item will
--			be shipped against.
--	Result		The result of running the procedure.  Same as return
--			value.
--
--	Returns:
--	    0	Success.
--	  -10	Invalid PO.
--	  -11	PO is not a drop ship.
--	  -20	Quantity must be greater than zero.
--	  -30	Order detail ID not found.
--	  -31	Order detail line item incompatable with PO.
--	 -999	Unknown error.
--
--	History:
--	08 JUN 2002, Eric Stimpson	Original.
--
--	Process:
--	I.	Validate parameters.
--		A.	PO exists.
--			1.	PO is drop ship.
--		B.	Quantity is greater than zero
--		C.	Order detail exists.
--			1.	Order detail line item is incompatable with PO.
--	II.	Add item to PO.
--		A.	If compatable item is found, add to PO Line Item.
--		B.	Create new PO line item.
--	III.	Return success.
---------------------------------------------------------------------------------------
set nocount on
set	@Result = 999999

--- <Error Handling>
declare	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=No>
declare	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
save tran @ProcName
--- </Tran>

--	Declarations.
declare	@OrderNO integer,
	@RowID integer

--	Initializations.
select	@OrderNO = order_no,
	@RowID = row_id
from	order_detail
where	id = @OrderDetailID

--	I.	Validate parameters.
--		A.	PO exists.
if not exists
(	select	1
	from	po_header
	where	po_number = @PONumber )
begin
	select	@Result = -10
	rollback tran @ProcName
	return	@Result
end

--			1.	PO is drop ship.
if
(	select	convert ( char (1), ship_type )
	from	po_header
	where	po_number = @PONumber and
		status = 'A' ) != 'D'
begin
	select	@Result = -11
	rollback tran @ProcName
	return	@Result
end

--		B.	Quantity is greater than zero
if not @Quantity > 0
begin
	select	@Result = -20
	rollback tran @ProcName
	return	@Result
end

--		C.	Order detail exists.
if not exists
(	select	1
	from	order_detail
	where	id = @OrderDetailID )
begin
	select	@Result = -30
	rollback tran @ProcName
	return	@Result
end

--			1.	Order detail line item is incompatable with PO.
if not exists
(	select	1
	from	order_detail
	where	id = @OrderDetailID and
		ship_type = 'D' and
		destination =
		(	select	ship_to_destination
			from	po_header
			where	po_number = @PONumber ) )
begin
	select	@Result = -31
	rollback tran @ProcName
	return	@Result
end

--	II.	Add item to PO.
--		A.	If compatable item is found, add to PO Line Item.
if exists
(	select	1
	from	po_detail
		join order_detail on po_detail.sales_order = order_detail.order_no and
			po_detail.dropship_oe_row_id = order_detail.row_id and
			order_detail.id = @OrderDetailID
	where	po_detail.po_number = @PONumber )
	
	update	po_detail
	set	po_detail.balance = po_detail.balance + @Quantity,
		po_detail.quantity = po_detail.quantity + @Quantity,
		po_detail.standard_qty = ( po_detail.balance + @Quantity ) * IsNull (
		(	select	uc.conversion
			from	part_vendor pv
				join part_inventory pi on po_detail.part_number = pi.part
				join part_unit_conversion puc on po_detail.part_number = puc.part
				join unit_conversion uc on puc.code = uc.code and
					uc.unit1 = pv.receiving_um and
					uc.unit2 = pi.standard_unit
			where	po_detail.part_number = pv.part and
				po_detail.vendor_code = pv.vendor ), 1 ),
		po_detail.price = @Price
	from	po_detail
		join order_detail on po_detail.sales_order = order_detail.order_no and
			po_detail.dropship_oe_row_id = order_detail.row_id and
			order_detail.id = @OrderDetailID
	where	po_detail.po_number = @PONumber

--		B.	Create new PO line item.
else
	insert	po_detail
	(	po_number,
		vendor_code,
		part_number,
		description,
		unit_of_measure,
		date_due,
		status,
		account_code,
		quantity,
		received,
		balance,
		alternate_price,
		row_id,
		release_no,
		ship_to_destination,
		terms,
		week_no,
		plant,
		standard_qty,
		sales_order,
		dropship_oe_row_id,
		ship_type,
		price_unit )
	select	@PONumber,
		(	select	vendor_code
			from	po_header
			where	po_number = @PONumber ),
		order_detail.part_number,
		(	select	name
			from	part
			where	order_detail.part_number = part ),
		(	select	pv.receiving_um
			from	part_vendor pv
			where	order_detail.part_number = pv.part and
				pv.vendor =
				(	select	vendor_code
					from	po_header
					where	po_number = @PONumber ) ),
		order_detail.due_date,
		'A',
		(	select	gl_account_code
		    	from    part_purchasing
		   	where   order_detail.part_number = part ),
		@Quantity,
		0,
		@Quantity,
		@Price,
		IsNull (
		(	select	max ( row_id )
			from	po_detail
			where	po_number = @PONumber ) + 1, 1 ),
		(	select	release_no
			from	po_header
			where	po_number = @PONumber ),
		order_detail.destination,
		(	select	po_header.terms
			from	po_header
			where	po_header.po_number = @PONumber ),
		(	select	DateDiff ( wk, parameters.fiscal_year_begin, GetDate ( ) )
			from	parameters ),
		order_detail.plant,
		@Quantity * IsNull (
		(	select	uc.conversion
			from	part_vendor pv
				join part_inventory pi on order_detail.part_number = pi.part
				join part_unit_conversion puc on order_detail.part_number = puc.part
				join unit_conversion uc on puc.code = uc.code and
					uc.unit1 = pv.receiving_um and
					uc.unit2 = pi.standard_unit
			where	order_detail.part_number = pv.part and
				pv.vendor =
				(	select	vendor_code
					from	po_header
					where	po_number = @PONumber ) ), 1 ),
		order_detail.order_no,
		order_detail.row_id,
		'D',
		'P'
	from	order_detail
	where	order_detail.id = @OrderDetailID

--	Check results:
if @@RowCount != 1
begin
	select	@Result = -999
	rollback tran @ProcName
	return	@Result
end

--<CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit transaction @ProcName
end
--</CloseTran Required=Yes AutoCreate=Yes>

--	III.	Return success.
select	@Result = 0
return	@Result
GO
