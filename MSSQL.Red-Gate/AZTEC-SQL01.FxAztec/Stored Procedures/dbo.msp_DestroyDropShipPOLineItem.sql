SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[msp_DestroyDropShipPOLineItem]
(	@PONumber integer,
	@RowID integer,
	@Result integer = null output )
as
---------------------------------------------------------------------------------------
--	Description:
--	This procedure removes a line item from the specified PO.
--
--	Parameters:
--	PONumber	The PO Number to remove the line from.
--	RowID		The RowID of the line.
--	Result		The result of running the procedure.  Same as return
--			value.
--
--	Returns:
--	    0	Success.
--	  -10	Invalid PO.
--	  -11	PO is not a drop ship.
--	  -12	Invalid line item.
--	 -999	Unknown error.
--
--	History:
--	08 JUN 2002, Eric Stimpson	Original.
--
--	Process:
--	I.	Validate parameters.
--		A.	PO exists.
--			1.	PO is drop ship.
--			2.	Line item exists.
--	II.	Delete line from PO.
--	III.	Return success.
---------------------------------------------------------------------------------------
begin transaction

--	Declarations.
declare	@OrderNO integer,
	@OERowID integer

--	Initializations.
select	@OrderNO = sales_order,
	@OERowID = dropship_oe_row_id
from	po_detail
where	po_number = @PONumber and
	row_id = @RowID

--	I.	Validate parameters.
--		A.	PO exists.
if not exists
(	select	1
	from	po_header
	where	po_number = @PONumber )
begin
	select	@Result = -10
	rollback
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
	rollback
	return	@Result
end

--			2.	Line item exists.
if not exists
(	select	ship_type
	from	po_detail
	where	po_number = @PONumber and
		row_id = @RowID )
begin
	select	@Result = -12
	rollback
	return	@Result
end


--	II.	Delete line from PO.
delete	po_detail
where	po_number = @PONumber and
	row_id = @RowID

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
