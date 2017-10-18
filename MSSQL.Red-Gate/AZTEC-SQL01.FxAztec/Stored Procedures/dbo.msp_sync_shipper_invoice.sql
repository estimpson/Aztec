SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_sync_shipper_invoice]
(	@shipper	integer )
as
---------------------------------------------------------------------------------------
-- 	This procedure is executed when a normal or quick shipper is shipped out to
--	synchronize the shipper number and invoice number
--
--	Arguments:
--	
--	@shipper	integer		mandatory
--
--	Modifications:	27 SEP 1999, Chris Rogers	Original
--			23 NOV 1999, Chris Rogers	Added check for sync switch in admin table
--
--	Returns:	 0		success
--			-1		error
--
--	Process:
--	1.	Update invoice_number with the value in the id column in the shipper table
---------------------------------------------------------------------------------------

--	1.	Update invoice_number with the value in the id column in the shipper table
if exists ( select 1 from admin where db_invoice_sync = 'Y' )
begin
	update	shipper 
	set	invoice_number = id
	where	id = @shipper
	
	exec msp_sync_parm_shipper_invoice
end
GO
