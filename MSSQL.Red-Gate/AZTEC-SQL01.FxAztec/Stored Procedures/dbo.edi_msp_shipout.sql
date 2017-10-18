SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[edi_msp_shipout]
(	@shipper	integer )
as
-- 	1.	Record shipout for homogeneous pallet with part id of boxes.
insert	serial_asn
select	pallet.serial,
	max ( boxes.part ),
	convert ( integer, pallet.shipper ),
	pallet.package_type
from	object pallet 
	join object boxes on pallet.serial = boxes.parent_serial
where	pallet.shipper = @shipper and
	pallet.type = 'S'
group by	pallet.serial,
	pallet.shipper,
	pallet.package_type
having	count ( distinct boxes.part ) = 1
	
--	2.	Record shipout for loose box.
insert	serial_asn
select	serial,
	part,
	convert ( integer, shipper ),
	package_type
from	object
where	shipper = @shipper and
	parent_serial is null and
	type is null
GO
