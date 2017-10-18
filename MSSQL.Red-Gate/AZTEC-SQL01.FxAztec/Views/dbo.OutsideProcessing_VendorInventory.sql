SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[OutsideProcessing_VendorInventory]
as
select
	PartCode = o.part
,	VendorLocation = o.location
,	SystemQuantity = sum(o.std_quantity)
,	AdjustedQuantity = null
from
	dbo.object o
where
	location in
		(	select
		 		d.destination
		 	from
		 		dbo.part_vendor pv
		 		join dbo.destination d
		 			on d.vendor = pv.vendor
		 	where
		 		pv.part = o.part
		)
group by
	o.part
,	o.location
GO
