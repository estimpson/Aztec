SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[monsp_ReceiveLineItem]
(	@Operator varchar (5),
	@PONumber integer,
	@POLineItem integer,
	@Quantity numeric (20,6),
	@Objects integer,
	@Location varchar (10),
	@ShipperID varchar (20) = null,
	@PackageCode varchar (20) = null,
	@LotNumber varchar (20) = null,
	@Custom1 varchar (50) = null,
	@Custom2 varchar (50) = null,
	@Custom3 varchar (50) = null,
	@Custom4 varchar (50) = null,
	@Custom5 varchar (50) = null,
	@Custom6 varchar (50) = null,
	@Note varchar (255) = null,
	@ReceiveDT datetime = null,
	@Serial integer = null output,
	@Result integer = null output )
as
--------------------------------------------------------------------------------
--	File:
--	monsp_ReceiveLineItem
--
--	Description:
--	Receive a line item.
--
--	Arguments:
--	Operator	The operator performing the transaction
--	...
--	Result		The result of running the procedure.  Same as the return
--			value.
--
--	Returns:
--	    0	Success.
--	 -999	Unknown error.
--
--	History:
--	?? ??? ????, Eric Stimpson	Original.
--	24 Aug 2002, Eric Stimpson	Added Receive Date parameter for pre-
--					dating receive transaction.
--
--	Process:
--	I.	Declarations and Initializations.
--		A.	Declarations.
--		B.	Initalize conversion factor.
--		C.	Initialize date received.
--	II.	Validate data.
--		A.	Operator code must be valid.
--		B.	Purchase order must be valid, open, and line item
--			controlled.
--		C.	Line item must be valid, open, and for a reoccurring
--			part.
--		D.	Quantity must be positive.
--		E.	Number of objects must be positive.
--		F.	Location code must be valid.
--		G.	If shipper is required it must be specified.
--		H.	Package code, if specified, must be valid.
--	III.	Generate Inventory.
--		A.	Get block of serial numbers.
--		B.	Create Objects, update Part Online, and create Audit
--			Trail records.
--	IV.	Update Purchase Order and Part-Vendor relationship.
--		A.	Update the Line Item with receipt quantities and date.
--		B.	Create receipt history.
--		C.	Update Part-Vendor relationship.
--	V.	Success.
-------------------------------------------------------------------------------
begin transaction

--	I.	Declarations and Initializations.
--		A.	Declarations.
declare	@ObjCount integer,
	@Conversion numeric (20,14)

--		B.	Initalize conversion factor.
select	@Conversion = isnull ( conversion, 1 )
from	po_detail
	left outer join part_inventory on po_detail.part_number = part_inventory.part
	left outer join part_unit_conversion on po_detail.part_number = part_unit_conversion.part
	left outer join unit_conversion on part_unit_conversion.code = unit_conversion.code and
		unit_conversion.unit1 = part_inventory.standard_unit and
		unit_conversion.unit2 = po_detail.unit_of_measure
where	po_detail.po_number = @PONumber and
	po_detail.row_id = @POLineItem

--		C.	Initialize date received.
select	@ReceiveDT = IsNull ( @ReceiveDT, GetDate ( ) )

--	II.	Validate data.
--		A.	Operator code must be valid.
--		B.	Purchase order must be valid, open, and line item controlled.
--		C.	Line item must be valid, open, and for a reoccurring part.
--		D.	Quantity must be positive.
--		E.	Number of objects must be positive.
--		F.	Location code must be valid.
--		G.	If shipper is required it must be specified.
--		H.	Package code, if specified, must be valid.

--	III.	Generate Inventory.
--		A.	Get block of serial numbers.
update	parameters
set	next_serial = next_serial + @Objects

if @@error != 0
begin
	rollback
print 'IIIA.'
	select	@Result = -999
	return	@Result
end

select	@Serial = next_serial - @Objects
from	parameters

while exists
(	select	serial
	from	object
	where	serial between @Serial and @Serial + @Objects - 1 )
	select	@Serial = @Serial + 1

update	parameters
set	next_serial = @Serial + @Objects

if @@error != 0
begin
	rollback
print 'IIIA.(2)'
	select	@Result = -999
	return	@Result
end

--		B.	Create Objects, update Part Online, and create Audit Trail records.
select	@ObjCount = 0
while	@ObjCount < @Objects
begin	-- (1b)
	insert	object
	(	serial,
		part,
		lot,
		location,
		last_date,
		unit_measure,
		operator,
		status,
		origin,
		cost,
		note,
		po_number,
		name,
		plant,
		quantity,
		last_time,
		package_type,
		std_quantity,
		custom1,
		custom2,
		custom3,
		custom4,
		custom5,
		user_defined_status,
		std_cost )
	select	@Serial + @ObjCount,
		po_detail.part_number,
		@LotNumber,
		@Location,
		getdate ( ),
		po_detail.unit_of_measure,
		@Operator,
		(	case	when isnull ( part.quality_alert, 'N' ) = 'Y' then 'H'
				else 'A'
			end ),
		@ShipperID,
		po_detail.price / @Conversion,
		@Note,
		@PONumber,
		part.name,
		location.plant,
		@Quantity * @Conversion,
		getdate ( ),
		@PackageCode,
		@Quantity,
		@Custom1,
		@Custom2,
		@Custom3,
		@Custom4,
		@Custom5,
		(	case	when isnull ( part.quality_alert, 'N' ) = 'Y' then 'ON HOLD'
				else 'APPROVED'
			end ),
		po_detail.price / @Conversion
	from	po_detail
		join part on po_detail.part_number = part.part and
			part.class <> 'N'
		join location on code = @Location
	where	po_number = @PONumber and
		row_id = @POLineItem

	if @@error != 0
	begin
		rollback
print 'IIIB.'
		select	@Result = -999
		return	@Result
	end
	
	insert	audit_trail
	(	serial,
		date_stamp,
		type,
		part,
		quantity,
		remarks,
		price,
		vendor,
		po_number,
		operator,
		from_loc,
		to_loc,
		on_hand,
		lot,
		weight,
		status,
		shipper,
		unit,
		std_quantity,
		cost,
		control_number,
		custom1,
		custom2,
		custom3,
		custom4,
		custom5,
		plant,
		notes,
		gl_account,
		package_type,
		release_no,
		std_cost,
		user_defined_status,
		part_name,
		tare_weight )
	select	@Serial + @ObjCount,
		getdate ( ),
		'R',
		po_detail.part_number,
		@Quantity * @Conversion,
		'receiving',
		po_detail.price / @Conversion,
		po_header.vendor_code,
		@PONumber,
		@Operator,
		po_header.vendor_code,
		@Location,
		isnull ( part_online.on_hand, 0 ) + object.std_quantity * @ObjCount,
		@LotNumber,
		isnull ( object.weight, part_inventory.unit_weight * @Quantity ),
		(	case	when isnull ( part_vendor.outside_process, 'N' ) = 'Y' then 'P'
				else isnull ( object.status, 'A' )
			end ),
		@ShipperID,
		po_detail.unit_of_measure,
		@Quantity,
		po_detail.price / @Conversion,
		po_detail.requisition_id,
		@Custom1,
		@Custom2,
		@Custom3,
		@Custom4,
		@Custom5,
		location.plant,
		@Note,
		part_purchasing.gl_account_code,
		@PackageCode,
		po_detail.release_no,
		po_detail.price / @Conversion,
		(	case	when isnull ( part.quality_alert, 'N' ) = 'Y' then 'ON HOLD'
				else 'APPROVED'
			end ),
		isnull ( object.name, po_detail.description ),
		object.tare_weight
	from	parameters
		join location on code = @Location
		join po_header on po_header.po_number = @PONumber
		join po_detail on po_detail.po_number = @PONumber and
			po_detail.row_id = @POLineItem
		left outer join object on object.serial = @Serial + @ObjCount
		left outer join part on part.part = po_detail.part_number
		left outer join part_inventory on part_inventory.part = po_detail.part_number
		left outer join part_online on part_online.part = po_detail.part_number
		left outer join part_purchasing on part_purchasing.part = po_detail.part_number
		left outer join part_vendor on part_vendor.part = po_detail.part_number and
			part_vendor.vendor = po_header.vendor_code

	if @@error != 0
	begin
		rollback
print 'IIIB.(2)'
		select	@Result = -999
		return	@Result
	end
	
	select	@ObjCount = @ObjCount + 1
end	-- (1b)

update	part_online
set	on_hand =
	(	select	sum ( std_quantity )
		from	object
		where	part = part_online.part and
			status = 'A' )
where	part =
	(	select	part_number
		from	po_detail
		where	po_number = @PONumber and
			po_detail.row_id = @POLineItem )

if @@error != 0
begin
	rollback
print 'IIIB.(3)'
	select	@Result = -999
	return	@Result
end

--	IV.	Update Purchase Order and Part-Vendor relationship.
--		A.	Update the Line Item with receipt quantities and date.
update	po_detail
set	received = received + @Quantity * @Objects * @Conversion,
	balance = balance - @Quantity * @Objects * @Conversion,
	standard_qty = @Quantity * @Objects,
	last_recvd_date = @ReceiveDT,
	last_recvd_amount = @Quantity * @Objects * @Conversion
where	po_detail.po_number = @PONumber and
	po_detail.row_id = @POLineItem

if @@error != 0
begin
	rollback
print 'IVA.'
	select	@Result = -999
	return	@Result
end

--		B.	Create receipt history.
insert	po_detail_history
(	po_number,
	vendor_code,
	part_number,
	description,
	unit_of_measure,
	date_due,
	requisition_number,
	status,
	type,
	last_recvd_date,
	last_recvd_amount,
	cross_reference_part,
	account_code,
	notes,
	quantity,
	received,
	balance,
	active_release_cum,
	received_cum,
	price,
	row_id,
	invoice_status,
	invoice_date,
	invoice_qty,
	invoice_unit_price,
	release_no,
	ship_to_destination,
	terms,
	week_no,
	plant,
	invoice_number,
	standard_qty,
	sales_order,
	dropship_oe_row_id,
	ship_type,
	dropship_shipper,
	price_unit,
	ship_via,
	release_type,
	alternate_price )
select	po_detail.po_number,
	po_detail.vendor_code,
	po_detail.part_number,
	po_detail.description,
	po_detail.unit_of_measure,
	po_detail.date_due,
	po_detail.requisition_number,
	'C',
	po_detail.type,
	@ReceiveDT,
	@Quantity * @Objects,
	po_detail.cross_reference_part,
	po_detail.account_code,
	@Note,
	po_detail.quantity,
	po_detail.received,
	po_detail.balance,
	po_detail.active_release_cum,
	po_detail.received_cum,
	po_detail.price,
	po_detail.row_id,
	po_detail.invoice_status,
	po_detail.invoice_date,
	po_detail.invoice_qty,
	po_detail.invoice_unit_price,
	po_detail.release_no,
	po_detail.ship_to_destination,
	po_detail.terms,
	po_detail.week_no,
	po_detail.plant,
	po_detail.invoice_number,
	po_detail.standard_qty,
	po_detail.sales_order,
	po_detail.dropship_oe_row_id,
	po_detail.ship_type,
	po_detail.dropship_shipper,
	po_detail.price_unit,
	po_detail.ship_via,
	po_detail.release_type,
	po_detail.alternate_price
from	po_detail
where	po_detail.po_number = @PONumber and
	po_detail.row_id = @POLineItem

if @@error != 0
begin
	rollback
print 'IVB.'
	select	@Result = -999
	Raiserror ('Error (%d) error creating receipt history.', 16, 1, @Result)
	return	@Result
end

--		C.	Update Part-Vendor relationship.
update	part_vendor
set	accum_received = isnull ( accum_received, 0 ) + @Quantity * @Objects
where	part = 
	(	select	part_number
		from	po_detail
		where	po_number = @PONumber and
			po_detail.row_id = @POLineItem ) and
	vendor =
	(	select	vendor_code
		from	po_detail
		where	po_number = @PONumber and
			po_detail.row_id = @POLineItem )

if @@error != 0
begin
	rollback
print 'IVC.'
	select	@Result = -999
	return	@Result
end

--	V.	Success.
commit transaction
select	@Result = 0
return	@Result
GO
