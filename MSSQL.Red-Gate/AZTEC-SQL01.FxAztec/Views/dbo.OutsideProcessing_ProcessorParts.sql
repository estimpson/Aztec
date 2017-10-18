SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[OutsideProcessing_ProcessorParts]
as
select
	VendorCode = pvOut.vendor
,	VendorName = v.name
,	OutPartCode = xr.TopPart
,	OutPartDescription = pOut.name
,	OutVendorPart = pvOut.vendor_part
,	InPartCode = xr.ChildPart
,	InPartDescription = pIn.name
,	InVendorPart = pvIn.vendor_part
,	ActivityCode = ar.code
,	BOMQty = xr.XQty
,	StdScrapFactor = xr.XScrap
,	ReceivingUnit = coalesce(pvOut.receiving_um, piOut.standard_unit)
,	StandardUnit = piOut.standard_unit
,	APAccountCode = ppOut.gl_account_code
,	VendorStandardPack = pvOut.vendor_standard_pack
,	ProcessDays = coalesce(pvOut.lead_time, 0)
,	MinOrderQty = pvOut.min_on_order
,	PartVendorNote = pvOut.note
,	DefaultVendor = po.default_vendor
,	DefaultPO = po.default_po_number
,	BlanketPONumber = ph.po_number
,	BlanketPOEffectiveDate = ph.po_date
,	BlanketPOExpirationDate = convert(datetime, null)
from
	FT.XRt xr
	join dbo.part pOut
		join dbo.part_inventory piOut
			on piOut.part = pOut.part
		join dbo.part_purchasing ppOut
			on ppOut.part = pOut.part
		on pOut.part = xr.TopPart
	join dbo.part pIn
		on pIn.part = xr.ChildPart
	join dbo.part_vendor pvOut
		on pvOut.part = xr.TopPart
		and coalesce(pvOut.outside_process, 'Y') != 'N'
	join dbo.vendor v
		on v.code = pvOut.vendor
	left join dbo.activity_router ar
		on ar.parent_part = xr.TopPart
		and ar.sequence = 1
	left join dbo.part_vendor pvIn
		on pvIn.part = xr.ChildPart
		and pvIn.vendor = pvOut.vendor
	left join dbo.part_online po
		on po.part = xr.TopPart
	left join dbo.po_header ph
		on ph.vendor_code = pvOut.vendor
		and ph.blanket_part = xr.TopPart
where
	xr.BOMLevel = 1
GO
