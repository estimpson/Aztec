SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[msp_stage_object] (
 	@shipper integer, 
	@serial integer, 
	@parent_serial integer = null, 
	@create_sd char (1) = null, 
	@pkg_override char (1) = null,
	@result integer out )
as
---------------------------------------------------------------------------------------
-- 	This procedure stages an object to shipper.
--	parameter @shipper, @serial, @parent_serial, @create_sd, @pkg_override
--
--	Arguments:	@shipper    	mandatory
--			@serial     	mandatory
--			@parent_serial	optional
--			@create_sd	optional
--			@pkg_override	optional
--
--	Modifications:	02 MAR 1999, Mamatha Bettagere	Original.
--			04 MAY 1999, Mamatha Bettagere
--			09 JUN 1999, Eric E. Stimpson	Modified format.
--							Removed Package Type checking.
--							Moved part_original and part_required calculations to msp_reconcile_shipper.
--	
--	Returns:	 0	success
--			-1	shipper not found
--			-2	error, shipper was already closed
--			-3	error, invalid object
--			-4	error, object already staged to a shipper			
--			-5	package types don't match
--			-6	shipper type is 'v' and po number is null on object
--			-7	shipper type is 'o' and part/vendor relation doesn't exist
--
--	Process:
--	1. Ensure shipper is not closed.
--	2. Ensure shipper exists.
-- 	3. Check for valid, approved and not previously staged box.
--	4. Check for shipper type ( return to vendor type ) and po number.
--	5. Check for shipper type ( outside process ) and part vendor relationship
-- 	6. Check packing requirements.
-- 	7. If @create_sd then create shipper detail row
--	8. Stage a super object.
--	9. Stage a box.
-- 	10. Call reconcile shipper procedure to udpate shipper and shipper container tables
---------------------------------------------------------------------------------------

--	1. Ensure shipper is not closed.
if exists (
	select	1
	  from	shipper
	 where	id = @shipper and
		( status = 'C' or status = 'z' ) )	
	return -2

--	2. Ensure shipper exists.
if not exists (
	select	1
	  from	shipper
	 where	id = @shipper )	
	return -1

-- 	3. Check for valid, approved and not previously staged box.
if exists (
	select	1
	  from 	object
	 where	serial = @serial and
		( status <> 'A' and type <> 'S' ) )
	return -3
if exists (
	select	1
	  from 	object
	 where	serial = @serial and
		shipper > 0 )
	return -4

begin transaction

--	4. Check for shipper type ( return to vendor type ) and po number.
if exists (
	select	1
	  from	shipper
	  	cross join object
	 where	shipper = @shipper and
		serial = @serial and
		shipper.type = 'V' and
		object.type is null and
		IsNull ( po_number, '' ) = ''
	union
	select	1
	  from	shipper
	  	cross join object
	 where	shipper = @shipper and
		parent_serial = @serial and
		shipper.type = 'V' and
		IsNull ( po_number, '' ) = '' )
	return -6  


--	5. Check for shipper type ( outside process ) and part vendor relationship
if exists (
	select	1
	  from	shipper
		cross join object
	 where	shipper = @shipper and
		serial = @serial and
		shipper.type = 'O' and
		object.type is null and
		part not in (
		select	part
		  from	part_vendor )
	union
	select	1
	  from	shipper
		cross join object
	 where	shipper = @shipper and
		parent_serial = @serial and
		shipper.type = 'O' and
		part not in (
		select	part
		  from	part_vendor ) )
	return -7

-- 	6. Check packing requirements.

-- 	7. If @create_sd then create shipper detail row
if @create_sd = 'Y'
	execute msp_create_shipper_detail @shipper, @serial 

--	8. Stage a super object.
update	object
   set	shipper = @shipper,
	show_on_shipper = 'N'
 where	parent_serial = @serial

update	object
   set	shipper = @shipper,
	show_on_shipper = 'Y'
 where	serial = @serial and
	type = 'S'

--	9. Stage a box (to a pallet).
update	object
   set	shipper = @shipper,
	parent_serial = @parent_serial,
	show_on_shipper = (
		case
			when @parent_serial is null then 'Y'
			else 'N'
		end )
 where	serial = @serial and
	type is null

-- 	10. Call reconcile shipper procedure to udpate shipper and shipper container tables
execute @result = msp_reconcile_shipper @shipper 

commit transaction
return @result
GO
