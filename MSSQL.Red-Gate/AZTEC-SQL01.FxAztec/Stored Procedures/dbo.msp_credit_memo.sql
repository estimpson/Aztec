SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_credit_memo] 
	( @rma integer, 
	  @operator varchar (5),
	  @invoice integer OUTPUT )
as

--------------------------------------------------------------------------------
-- 	This procedure creates invoice for an existing and staged shipper. 
--
--	Modifications :	MB 	07/06/99 11:20 AM Original
--			 	07/13/99 14:19 PM Modified
--
--
-- 	Arguments   :	@rma integer - rma shipper for which credit memo is issued. 
--	            : 	@operator - operator who wants to issue credit memo.
--
-- 	Return      : 	0  successful
--		    : 	-1 if the shipper is closed
-- 
--	Process	    1. Check if the shipper is not closed yet 
--			2. Check if there are rows that need to be deleted from the shipper detail
--			3. Get the shipper and invoice number from parameters table
--			4. Otherwise, just update the shipper and let the sync take care of invoice
--			5. set a value -1 to invoice number in the else portion 
--			
--------------------------------------------------------------------------------
begin -- (1A)

        declare @status      varchar (1),
		@result	     integer 

--	1. check if the shipper is not closed yet 
	select @status = status
	from shipper 
	where id = @rma

	if @status = 'C' 
		return  -1 

--	2. check if there are rows that need to be deleted from the rma shipper detail
	delete shipper_detail
	where  ( qty_packed = 0 and shipper = @rma )

--      3. Get the shipper and invoice number from parameters table if sync invoice shipping is turned off
	if exists ( select 1 from admin where isnull(db_invoice_sync,'N') = 'N' )
	begin
	       	select  @invoice = next_invoice
	        from    parameters 
	
	        begin transaction
	
	               	update shipper
	       	        set   status = 'C',
	                      date_shipped = getdate(),
	               	      time_shipped = getdate(),
	       	              operator = @operator,
	                      invoice_number = @invoice,
	               	      invoice_printed = 'N'     
	       	        where id = @rma
	         
	       	        update parameters 
	                set next_invoice = @invoice + 1
	
	        commit transaction
	end
--		4. Otherwise, just update the shipper and let the sync take care of invoice
	else
	begin
	
	        begin transaction
	
	               	update shipper
	       	        set   status = 'C',
	                      date_shipped = getdate(),
	               	      time_shipped = getdate(),
	       	              operator = @operator,
	               	      invoice_printed = 'N',
	               	      invoice_number = -1
	       	        where id = @rma
	         
	        commit transaction
	end
	
        return 0 

end -- (1A)
GO
