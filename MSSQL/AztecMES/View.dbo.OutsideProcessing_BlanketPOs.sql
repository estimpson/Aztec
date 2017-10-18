
/*
Create view FxAztecTest.dbo.OutsideProcessing_BlanketPOs
*/

--use FxAztecTest
--go

--drop table dbo.OutsideProcessing_BlanketPOs
if	objectproperty(object_id('dbo.OutsideProcessing_BlanketPOs'), 'IsView') = 1 begin
	drop view dbo.OutsideProcessing_BlanketPOs
end
go

create view dbo.OutsideProcessing_BlanketPOs
as
select
	PONumber = ph.po_number
,	POEffectiveDate = ph.po_date
,	POExpirationDate = convert(datetime, null)
,	NextRelease = ph.release_no
,	ReleaseControl = ph.release_control
,	FreightType = ph.freight_type
,	Terms = ph.terms
,	FOB = ph.fob
,	TaxRate = ph.tax_rate
,	PONote = ph.notes
,	OrderingPlant = ph.plant
,	DeliveryShipTo = ph.ship_to_destination
,	VendorShipFrom = convert(varchar(25), null)
,	ShipType = ph.ship_type
,	Price = coalesce(ph.price, 0)
,	oppp.VendorCode
,   oppp.VendorName
,   oppp.OutPartCode
,   oppp.OutPartDescription
,   oppp.OutVendorPart
,   oppp.InPartCode
,   oppp.InPartDescription
,   oppp.InVendorPart
,   oppp.ActivityCode
,   oppp.BOMQty
,   oppp.StdScrapFactor
,	ReceivingUnit = coalesce (ph.std_unit, oppp.ReceivingUnit)
,	oppp.StandardUnit
,	oppp.APAccountCode
,   oppp.VendorStandardPack
,   oppp.ProcessDays
,   oppp.MinOrderQty
,   oppp.PartVendorNote
,	oppp.DefaultVendor
,	oppp.DefaultPO
from
	dbo.OutsideProcessing_ProcessorParts oppp
	join dbo.po_header ph
		on ph.vendor_code = oppp.VendorCode
		and ph.blanket_part = oppp.OutPartCode
go

select
	*
from
	dbo.OutsideProcessing_BlanketPOs
go

