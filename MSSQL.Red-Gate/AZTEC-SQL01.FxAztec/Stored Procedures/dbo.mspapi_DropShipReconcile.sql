SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[mspapi_DropShipReconcile]
(	@InvoiceNumber integer,
	@Result integer = null output )
as
--------------------------------------------------------------------------------
--	Description:
--	This procedure marks a drop ship invoice as completed.
--
--	Arguments:
--	InvoiceNumber	The invoice number that is completed.
--	Result		The result of running the procedure.  Same as the return
--			value.
--
--	Returns:
--	    0	Success.
--	   -1	Invalid invoice number.
--	   -2	Invoice is not a drop ship.
--	 -999	Unknown error.
--
--	History:
--	23 JUN 2002, Eric Stimpson	Created.
--
--	Process:
--	I.	Validate invoice.
--		A.	Invoice exists.
--		B.	Invoice is a drop ship.
--	II.	Mark invoice as reconciled.
--	III.	Return.
--------------------------------------------------------------------------------
begin transaction

--	I.	Validate invoice.
--		A.	Invoice exists.
if not exists
(	select	1
	from	shipper
	where	invoice_number = @InvoiceNumber )
begin
	select	@Result = -1
	rollback
	return	@Result
end

--		B.	Invoice is a drop ship.
if
(	select	type
	from	shipper
	where	invoice_number = @InvoiceNumber ) != 'D'
begin
	select	@Result = -2
	rollback
	return	@Result
end

--	II.	Mark invoice as reconciled.
update 	shipper
set	dropship_reconciled = 'Y'
where	invoice_number = @InvoiceNumber

if @@error != 0 or @@rowcount != 1
begin
	select	@Result = -999
	rollback
	return	@Result
end

--	III.	Return.
select	@Result = 0
return	@Result
GO
