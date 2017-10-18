SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[Purchasing_PurchaseOrderList]
as
select distinct
--	PONumber = coalesce(ph.CUSTOM_BestPO, convert(varchar(50), ph.po_number))
	PONumber = convert(varchar(50), ph.po_number)
,	VendorCode = ph.vendor_code
,	PODate = ph.po_date
,	DueDate = ph.date_due
,	Terms = ph.terms
,	FOB = ph.fob
,	ShipViaScac = ph.ship_via
,	ShipToDestination = ph.ship_to_destination
,	Status = ph.status
,	Type = ph.type
,	Description = ph.description
,	Plant = ph.plant
,	FreightType = ph.freight_type
,	BuyerName = ph.buyer
,	PrintedFlag = ph.printed
,	TotalAmount = ph.total_amount
,	FreightAmount = ph.shipping_fee
,	SalesTax = ph.sales_tax
,	BlanketQty = ph.blanket_orderded_qty
,	BlanketFrequency = ph.blanket_frequency
,	BlanketDuration = ph.blanket_duration
,	BlanketQtyPerRelease = ph.blanket_qty_per_release
,	BlanketPart = ph.blanket_part
,	PurchasePart = coalesce(ph.blanket_part, pd.part_number)
,	VendorPart = coalesce(ph.blanket_vendor_part, pv.vendor_part)
,	Price = ph.price
,	StandardUnit = ph.std_unit
,	ShipType = ph.ship_type
,	Flag = ph.flag
,	ReleaseNo = ph.release_no
,	ReleaseControl = ph.release_control
,	TaxRate = ph.tax_rate
,	ScheduledTime = ph.scheduled_time
,	InternalPONumber = ph.po_number
from
	dbo.po_header ph
	left join dbo.po_detail pd
		on pd.po_number = ph.po_number
	left join dbo.part_vendor pv
		on pv.vendor = ph.vendor_code
		and pv.part = coalesce(ph.blanket_part, pd.part_number)
GO
