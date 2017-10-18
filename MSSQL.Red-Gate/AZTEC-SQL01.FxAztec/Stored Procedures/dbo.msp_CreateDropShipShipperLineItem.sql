SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[msp_CreateDropShipShipperLineItem]
(	@Operator varchar (5),
	@ShipperID integer,
	@Quantity numeric (20,6),
	@PONumber integer,
	@PORowID integer,
	@Result integer = null output )
as
---------------------------------------------------------------------------------------
--	Description:
--	This procedure creates a drop ship shipper line item on the specified shipper.
--	If a compatable item is already found on the shipper (same po number and row id)
--	then the quantity is added to the existing shipper line item.
--
--	Parameters:
--	Operator	The operator performing the transaction.
--	ShipperID	The shipper number to add the line item to.
--	Quantity	The amount of an item being purchased.
--	PONumber	The PO number that was shipped against.
--	PORowID		The line item from the PO that was delivered.
--	Result		The result of running the procedure.  Same as return
--			value.
--
--	Returns:
--	    0	Success.
--	  -10	Invalid shipper.
--	  -11	Shipper is not a drop ship.
--	  -12	Shipper doesn't have the same delivery destination as the PO.
--	  -20	Quantity must be greater than zero.
--	  -30	PO not found.
--	  -31	PO line item not found.
--	  -32	PO line item incompatable with Shipper.
--	 -999	Unknown error.
--
--	History:
--	08 JUN 2002, Eric Stimpson	Original.
--
--	Process:
--	I.	Validate parameters.
--		A.	Shipper exists.
--			1.	Shipper is drop ship.
--			2.	Shipper has same ship to as PO.
--		B.	Quantity is greater than zero
--		C.	PO exists.
--			1.	PO line item exists.
--			2.	PO line item is incompatable with Shipper.
--	II.	Add item to Shipper.
--		A.	If compatable item is found, add to shipper line item.
--		B.	Create new shipper line item.
--	III.	Return success.
---------------------------------------------------------------------------------------
begin transaction

--	Declarations.
declare	@StdQuantity numeric (20,6),
	@POQuantity numeric (20,6)

--	Initializations.
--			1.	Conversion from Shipper quantity to standard
--				quantity.
select	@StdQuantity = @Quantity * IsNull (
(	select	uc.conversion
	from	po_detail pod
		join order_detail od on pod.sales_order = od.order_no and
			pod.dropship_oe_row_id = od.row_id
		join part_inventory pi on pod.part_number = pi.part
		join part_unit_conversion puc on pod.part_number = puc.part
		join unit_conversion uc on puc.code = uc.code and
			uc.unit1 = od.unit and
			uc.unit2 = pi.standard_unit
	where	pod.po_number = @PONumber and
		pod.row_id = @PORowID ), 1 )

--			2.	Calculate from standard quantity to po
--				quantity.
select	@POQuantity = @StdQuantity * IsNull (
(	select	uc.conversion
	from	po_detail pod
		join part_inventory pi on pod.part_number = pi.part
		join part_unit_conversion puc on pod.part_number = puc.part
		join unit_conversion uc on puc.code = uc.code and
			uc.unit1 = pi.standard_unit and
			uc.unit2 = pod.unit_of_measure
	where	pod.po_number = @PONumber and
		pod.row_id = @PORowID ), 1 )

--	I.	Validate parameters.
--		A.	Shipper exists.
if not exists
(	select	1
	from	shipper
	where	id = @ShipperID )
begin
	select	@Result = -10
	rollback
	return	@Result
end

--			1.	Shipper is drop ship.
if
(	select	type
	from	shipper
	where	id = @ShipperID and
		status in ( 'C', 'D', 'Z' ) ) != 'D'
begin
	select	@Result = -11
	rollback
	return	@Result
end

--			2.	Shipper has same ship to as PO.
if
(	select	destination
	from	shipper
	where	id = @ShipperID ) !=
(	select	ship_to_destination
	from	po_header
	where	po_number = @PONumber )
begin
	select	@Result = -12
	rollback
	return	@Result
end

--		B.	Quantity is greater than zero
if not @Quantity > 0
begin
	select	@Result = -20
	rollback
	return	@Result
end

--		C.	PO exists.
if not exists
(	select	1
	from	po_header
	where	po_number = @PONumber )
begin
	select	@Result = -30
	rollback
	return	@Result
end

--			1.	PO line item exists.
if not exists
(	select	1
	from	po_detail
	where	po_number = @PONumber and
		row_id = @PORowID )
begin
	select	@Result = -31
	rollback
	return	@Result
end

--			2.	PO line item is incompatable with Shipper.


--	II.	Add item to Shipper.
--		A.	If compatable item is found, add to shipper line Item.
if exists
(	select	1
	from	shipper_detail
		join shipper on shipper_detail.shipper = shipper.id and
			shipper.id = @ShipperID
	where	shipper_detail.dropship_po = @PONumber and
		shipper_detail.dropship_po_row_id = @PORowID )
	
	update	shipper_detail
	set	shipper_detail.qty_packed = shipper_detail.qty_packed + @Quantity,
		shipper_detail.qty_required = shipper_detail.qty_required + @Quantity,
		shipper_detail.qty_original = shipper_detail.qty_original + @Quantity,
		shipper_detail.alternative_qty = ( shipper_detail.qty_packed + @Quantity ) * IsNull (
		(	select	uc.conversion
			from	part_inventory pi
				join part_unit_conversion puc on shipper_detail.part_original = puc.part
				join unit_conversion uc on puc.code = uc.code and
					uc.unit1 = shipper_detail.alternative_unit and
					uc.unit2 = pi.standard_unit
			where	pi.part = shipper_detail.part_original ), 1 )
	from	dbo.shipper_detail
		join shipper on shipper_detail.shipper = shipper.id and
			shipper.id = @ShipperID
	where	shipper_detail.dropship_po = @PONumber and
		shipper_detail.dropship_po_row_id = @PORowID

--		B.	Create new shipper line item.
else
	insert	shipper_detail
	(	shipper,
		part,
		qty_required,
		qty_packed,
		qty_original,
		accum_shipped,
		order_no,
		customer_po,
		price,
		alternate_price,
		account_code,
		salesman,
		date_shipped,
		operator,
		alternative_qty,
		alternative_unit,
		week_no,
		price_type,
		customer_part,
		dropship_po,
		dropship_po_row_id,
		dropship_oe_row_id,
		part_name,
		part_original,
		total_cost )
	select	shipper.id,
		po_detail.part_number +
		(	case when exists ( select 1 from shipper_detail where shipper = shipper.id and part_original = po_detail.part_number ) then
				'-' + convert ( varchar, ( select count ( 1 ) from shipper_detail where shipper = shipper.id and part_original = po_detail.part_number ) )
				else ''
			end ),
		@Quantity,
		@Quantity,
		@Quantity,
		@Quantity + order_header.our_cum,
		po_detail.sales_order,
		order_header.customer_po,
		order_detail.price,
		order_detail.alternate_price,
		(	select	gl_account_code
			from	part
			where	part = po_detail.part_number ),
		order_header.salesman,
		GetDate ( ),
		@Operator,
		@StdQuantity,
		(	select	unit
			from	order_detail
			where	order_no = po_detail.sales_order and
				row_id = po_detail.dropship_oe_row_id ),
		(	select	DateDiff ( wk, fiscal_year_begin, GetDate ( ) )
			from	parameters ),
		IsNull (
		(	select	price_unit
			from	order_header
			where	order_no = po_detail.sales_order and
				order_type = 'B' ), 'P' ),
		order_detail.customer_part,
		po_detail.po_number,
		po_detail.row_id,
		po_detail.dropship_oe_row_id,
		(	select	name
			from	part
			where	part = po_detail.part_number ),
		po_detail.part_number,
		@POQuantity * po_detail.alternate_price
	from	shipper
		join po_detail on po_detail.po_number = @PONumber and
			po_detail.row_id = @PORowID
		join order_header on po_detail.sales_order = order_header.order_no
		join order_detail on po_detail.sales_order = order_detail.order_no and
			po_detail.dropship_oe_row_id = order_detail.row_id
	where	shipper.id = @ShipperID

--	Check results:
if @@RowCount != 1
begin
	select	@Result = -999
	rollback
	return	@Result
end
else
--		C.	Make sure shipper is marked as approved.
	update	shipper
	set	status = 'A'
	where	id = @ShipperID

--	Check results:
if @@RowCount != 1
begin
	select	@Result = -999
	rollback
	return	@Result
end

--	III.	Return success.
select	@Result = 0
return	@Result
GO
