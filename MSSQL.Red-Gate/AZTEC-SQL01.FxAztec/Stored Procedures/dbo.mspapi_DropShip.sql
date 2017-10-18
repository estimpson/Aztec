SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[mspapi_DropShip]
(	@Operator varchar (25),
	@ShipperID integer,
	@InvoiceNumber integer = null output,
	@Result integer = null output )
as
--------------------------------------------------------------------------------
--	Description:
--	This procedure performs a receive, stage, and ship transaction for a
--	Drop Ship order.
--
--	Arguments:
--	Operator	The operator code of the person performing the
--			transaction.
--	ShipperID	The shipper that has been received by the customer.
--	InvoiceNumber	Used to return the new invoice number generated as a
--			result of running this transaction.
--	Result		The result of running the procedure.  Same as the return
--			value.
--
--	Returns:
--	    0	Success.
--	   -1	Invalid operator code.
--	-1nnn	Error receiving against PO.
--	-2nnn	Error staging to shipper.
--	-3nnn	Error recording ship out.
--
--	History:
--	23 JUN 2002, Eric Stimpson	Created.
--
--	Process:
--	I.	Loop through each line item on the shipper.
--		A.	Receive the corresponding PO line item.
--			1.	If the line item is fully received, delete it.
--			2.	If the PO is fully received, close it.
--		B.	Record the serial number used for the transaction in
--			shipper detail.
--		C.	Stage newly received item to the shipper.
--	II.	Record shipout.
--		A.	Prepare shipper for shipping.
--		B.	Perform shipout.
--			1.	Get the newly generated invoice number
--	III.	Return.
--------------------------------------------------------------------------------
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

--	Declarations:
declare	@PONumber integer,
	@POLineItem integer,
	@Serial integer,
	@Location varchar (10),
	@StdQty numeric (20,6)

declare	LineItems cursor local for
select	shipper_detail.alternative_qty,
	po_detail.po_number,
	po_detail.row_id,
	part_inventory.primary_location
from	shipper_detail
	join part_inventory on shipper_detail.part_original = part_inventory.part
	join po_detail on shipper_detail.dropship_po = po_detail.po_number and
		shipper_detail.dropship_po_row_id = po_detail.row_id
where	shipper = @ShipperID

--	I.	Loop through each line item on the shipper.
open	LineItems

fetch	LineItems
into	@StdQty,
	@PONumber,
	@POLineItem,
	@Location

while @@fetch_status = 0
begin
--		A.	Receive the corresponding PO line item.
	execute	monsp_ReceiveLineItem
		@Operator = @Operator,
		@PONumber = @PONumber,
		@POLineItem = @POLineItem,
		@Quantity = @StdQty,
		@Objects = 1,
		@Location = @Location,
		@Serial = @Serial out,
		@Result = @Result out
	
	if @@error != 0
	begin
		rollback
		select	@Result = -999
		return	@Result
	end
	
	if @Result != 0
	begin
		rollback
		select	@Result = @Result - 1000
		return	@Result
	end

--			1.	If the line item is fully received, delete it.
	delete	po_detail
	where	po_number = @PONumber and
		row_id = @POLineItem and
		balance <= 0

	if @@error != 0
	begin
		rollback
		select	@Result = -999
		return	@Result
	end
	
--			2.	If the PO is fully received, close it.
	update	po_header
	set	status = 'C'
	where	po_number = @PONumber and
		not exists
		(	select	1
			from	po_detail
			where	po_number = @PONumber )
	
	if @@error != 0
	begin
		rollback
		select	@Result = -999
		return	@Result
	end

--		B.	Record the serial number used for the transaction in
--			shipper detail.
	update	shipper_detail
	set	dropship_po_serial = @Serial,
		dropship_invoice_serial = @Serial
	where	shipper = @ShipperID
	
	if @@error != 0
	begin
		rollback
		select	@Result = -999
		return	@Result
	end
	
--		C.	Stage newly received item to the shipper.
	execute	msp_stage_object
		@shipper = @ShipperID,
		@serial = @Serial,
		@result = @Result out
	
	if @@error != 0
	begin
		rollback
		select	@Result = -999
		return	@Result
	end
	
	if @Result != 0
	begin
		rollback
		select	@Result = @Result - 2000
		return	@Result
	end
	
	fetch	LineItems
	into	@StdQty,
		@PONumber,
		@POLineItem,
		@Location
end

--	II.	Record shipout.
--		A.	Prepare shipper for shipping.
update	shipper
set	operator = @Operator
where	id = @ShipperID

if @@error != 0
begin
	rollback
	select	@Result = -999
	return	@Result
end

--		B.	Perform shipout.
execute	msp_shipout
	@ShipperID = @ShipperID,
	@Result = @Result out

if @@error != 0
begin
	rollback
	select	@Result = -999
	return	@Result
end

if @Result != 0
begin
	rollback
	select	@Result = @Result - 3000
	return	@Result
end

--			1.	Get the newly generated invoice number
select	@InvoiceNumber = invoice_number
from	shipper
where	id = @ShipperID

--<CloseTran Required=Yes AutoCreate=Yes>
if	@TranCount = 0 begin
	commit transaction @ProcName
end
--</CloseTran Required=Yes AutoCreate=Yes>

--	III.	Return.
select	@Result = 0
return	@Result
GO
