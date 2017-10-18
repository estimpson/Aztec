
/*
Create view fxAztec.dbo.OutsideProcessing_VendorInventory
*/

--use fxAztecTest
--go

--drop table dbo.OutsideProcessing_VendorInventory
if	objectproperty(object_id('dbo.OutsideProcessing_VendorInventory'), 'IsView') = 1 begin
	drop view dbo.OutsideProcessing_VendorInventory
end
go

create view dbo.OutsideProcessing_VendorInventory
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
go

select
	opvi.PartCode
,	opvi.VendorLocation
,	opvi.SystemQuantity
,	opvi.AdjustedQuantity
from
	dbo.OutsideProcessing_VendorInventory opvi
