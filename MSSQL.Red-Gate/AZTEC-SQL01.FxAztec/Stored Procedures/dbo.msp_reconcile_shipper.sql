SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[msp_reconcile_shipper]
(	@shipper	integer )
as
---------------------------------------------------------------------------------------
-- 	This procedure reconciles the quantity and standard quantity staged to a shipper,
--	caculates the shipper container information, sets boxes and pallets staged
--	fields in shipper detail and shipper header, and sets the status of the shipper to
--	(S)taged or (O)pen as appropriate.
--	This procedure sets quantity original and quantity required on Outside Process,
--	Return to Vendor, and Quick Shippers.  Unused line items are removed.
--
--	Arguments:	@shipper	mandatory
--
--	Modifications:	09 FEB 1999, Eric E. Stimpson	Original
--			09 JUN 1999, Eric E. Stimpson	Modified format.
--							Added computation of quantity original and quantity required.
--							Added removal of unused line items.
--
--	Returns:	 0		success
--			-1		shipper not found
--			-2		error, shipper was already closed
--			-3		error, invalid part was staged to this shipper
--
--	Process:
--	1. Ensure shipper is not closed.
--	2. Ensure shipper exists.
--	3. Ensure no invalid parts are staged to this shipper.
--	4. Reconcile quantity and standard quantity staged to shipper.
--	5. Refresh shipper container information.
--	6. Set boxes and pallets staged fields in shipper detail and shipper header.
--	7. Set the status of the shipper to (S)taged or (O)pen.
--	8. Set quantity original and quantity required on Quick, RTV, or Outside shippers.
--	9. Remove shipper detail with no quantity required.
---------------------------------------------------------------------------------------

--	1. Ensure shipper is not closed.
if exists (
	select	1
	  from	shipper
	 where	id = @shipper and
		( type = 'C' or type = 'Z' ) )
		return -2

--	2. Ensure shipper exists.
if not exists (
	select	1
	  from	shipper
	 where	id = @shipper )
	return -1

--	3. Ensure no invalid parts are staged to this shipper.
if exists (
	select	1
	  from	object
	 where	shipper = @shipper and
		type is null and
		part not in (
		select	part_original
		  from	shipper_detail
		 where	shipper = @shipper ) )
		return -3

--	4. Reconcile quantity and standard quantity staged to shipper.
begin transaction

update	shipper_detail
   set	qty_packed =
		(select	sum ( box.quantity )
		  from	object box
		 where	shipper_detail.part_original = box.part and
			isnull ( shipper_detail.suffix, 0 ) = isnull ( box.suffix, 0 ) and
			box.type is null and
			box.shipper = @shipper ),
	alternative_qty =
		(select	sum ( box.std_quantity )
		  from	object box
		 where	shipper_detail.part_original = box.part and
				isnull ( shipper_detail.suffix, 0 ) = isnull ( box.suffix, 0 ) and
				box.type is null and
				box.shipper = @shipper ),	
	boxes_staged = 
		(select count ( 1 )
		 from object box 
		 where shipper_detail.part_original = box.part and
			isnull ( shipper_detail.suffix, 0 ) = isnull ( box.suffix, 0 ) and
			box.type is null and 
			box.shipper = @shipper )
 where	shipper = @shipper 

--	5. Refresh shipper container information.
delete	shipper_container
 where	shipper = @shipper


insert	shipper_container (
		shipper,
		container_type,
		quantity,
		weight,
		group_flag )
select	shipper,
	package_type,
	count ( 1 ),
	null,
	null
  from	object
 where	shipper = @shipper and
	package_type > ''
group by shipper,
	package_type

--	6. Set boxes and pallets staged fields in shipper detail and shipper header.
update	shipper
   set	staged_objs = (
   		select	count ( 1 )
		  from	object box
		 where	box.type is null and
				box.shipper = @shipper ),
	staged_pallets = (
		select	count ( 1 )
		  from	object pallet
		 where	pallet.type = 's' and
			pallet.shipper = @shipper )
 where	id = @shipper

--	7. Set the status of the shipper to (S)taged or (O)pen.
update	shipper
   set	status = isnull ( (
   		select	max ( 'O' )
		  from	shipper_detail sd
			left outer join order_detail od on sd.order_no = od.order_no and
				sd.part_original = od.part_number and
				isnull ( sd.suffix, 0 ) = isnull ( od.suffix, 0 )
			left outer join part_packaging pp on pp.part = sd.part_original
				and pp.code = od.packaging_type
		 where	sd.shipper = @shipper and
		 	(	(	isnull ( alternative_qty, 0 ) < qty_required and
					isnull ( pp.stage_using_weight, 'N' ) <> 'Y' ) or
				(	isnull ( gross_weight, 0 ) < qty_required and
					pp.stage_using_weight = 'Y' ) ) ), 'S' )
 where	id = @shipper

--	8. Set quantity original and quantity required on Quick, RTV, or Outside shippers.
update	shipper_detail
   set	qty_required = qty_packed,
   	qty_original = qty_packed
  from	shipper
 where	shipper = @shipper and
 	id = shipper and
 	( shipper.type = 'V' or shipper.type = 'Q' or shipper.type = 'O' )

--	9. Remove shipper detail with no quantity required.
delete
	sd
from
	dbo.shipper_detail sd
	join dbo.shipper s
		on s.id = sd.shipper
where
	sd.qty_required = 0
	and s.type != 'M'
	and s.date_shipped is null
		
commit transaction
return 0
GO
