SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_sync_parm_shipper_invoice]
as
---------------------------------------------------------------------------------------
-- 	This procedure is executed when a parameter record is updated to set the 
--	next_invoice number to shipper number.
--
--	Modifications:	27 SEP 1999, Chris Rogers	Original
--			23 NOV 1999, Chris Rogers	Added check for sync switch in admin table
--
--	Returns:	 0		success
--			-1		error
--
--	Process:
--	1.	Update next_invoice with the value in the shipper column in parameters table
---------------------------------------------------------------------------------------

--	1.	Update next_invoice with the value in the shipper column in parameters table
if exists ( select 1 from admin where db_invoice_sync = 'Y' )
	update	parameters
	set	next_invoice = shipper
GO
