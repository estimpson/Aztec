SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_unstage_object] (
	@shipper integer,
	@serial integer,
	@result integer out )
as
---------------------------------------------------------------------------------------
-- 	This procedure unstages an object from shipper.
--
--	Arguments:	@shipper	mandatory
--			@serial		mandatory
--
--	Modifications:	30 APR 1999, Mamatha Bettagere	Original.
--			09 JUN 1999, Eric E. Stimpson	Modified format.
--							Moved shipper_detail removal to msp_reconcile_shipper.
--
--	Returns:	0	    success
--
--	Process:
--	1. Unstage a super object.
--	2. Unstage an box (from a pallet).
-- 	3. Call reconcile shipper procedure to udpate shipper and shipper container tables
---------------------------------------------------------------------------------------

begin transaction

--	1. Unstage a super object.
update	object
   set	shipper = null,
	show_on_shipper = null
 where	serial = @serial and
	type = 'S'

update	object
   set	shipper = null,
	show_on_shipper = null
 where	parent_serial = @serial

--	2. Unstage an box (from a pallet).
update	object
   set	shipper = null,
	show_on_shipper = null,
	parent_serial = null
 where	serial = @serial and
 	type is null
 
-- 	3. Call reconcile shipper procedure to udpate shipper and shipper container tables
execute @result = msp_reconcile_shipper @shipper 

commit transaction
return @result
GO
