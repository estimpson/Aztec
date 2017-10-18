SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_reverse_rma_object] 
	( @serial integer, 
	  @rma integer )
as
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--	Msp_reverse_rma_object procedure deletes an object and its audit trail entry from the database and  reconciles 
--	rma shipper.
--	
--	Modifications :	MB 09/26/99	 Modified
--				Modified the stored procedure to accept two arguments and also included
--				Code to call msp_reconcile_rma_shipper to update shipper tables.
--
--	Arguments 	@serial integer : The Object serial that is being deleted 
--			@rma   integer : The RMA shipper number
--
--	Returns:		0 Success
--			-1 If the serial number does not exist
--
--	Process:		1.  Get the serial and origin from the audit trail record 	
--			2. Return  -1 if object is invalid
--			3. Delete object record	
--			4. Delete audit trail record
--			5. Call msp_reconcile_rma_shipper procedure to reconcile shipper table quantities
--
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

begin
	declare 	@audit_serial integer
	declare 	@origin varchar (25)
	
--	1. Get the serial and origin from the audit trail record 	
	select 	@audit_serial = serial, 
		@origin = origin
	from 	audit_trail
	where 	serial = @serial and
        		type = 'U'

--	2. Return  -1 if object is invalid
	if @audit_serial <= 0  or @audit_serial is null
		return -1
		
	begin transaction
	begin
	
--		3. Delete object record	
		delete from object
		where serial = @serial 

--		4. Delete audit trail record
		delete audit_trail
		where serial = @serial and type = 'U'

--		5. Call msp_reconcile_rma_shipper procedure to reconcile shipper table quantities
		execute msp_reconcile_rma_shipper @rma 

	end	

	commit transaction
	return 0
end
GO
