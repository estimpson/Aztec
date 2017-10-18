SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [fordEDI].[BlanketOrders]
as
select
	BlanketOrderNo = oh.order_no
,	ShipToCode = left(oh.destination,5)
,	EDIShipToCode = es.parent_destination
,	ShipToConsignee = es.pool_code
,	SupplierCode = es.supplier_code
,	CustomerPart = oh.customer_part
,	CustomerPO = oh.customer_po
,	CheckCustomerPO = convert(bit, case coalesce(check_po, 'N') when 'Y' then 1 else 0 end)
,	ModelYear = oh.model_year
,	CheckModelYear = convert(bit, case coalesce(check_model_year, 'N') when 'Y' then 1 else 0 end)
,	PartCode = oh.blanket_part
,	OrderUnit = oh.shipping_unit
,	LastSID = oh.shipper
,	LastShipDT = s.date_shipped
,	LastShipQty = (select max(qty_packed) from dbo.shipper_detail where shipper = oh.shipper and order_no = oh.order_no)
,	PackageType = oh.package_type
,	UnitWeight = pi.unit_weight
,	AccumShipped = oh.our_cum
,	InternalShipTo = oh.destination
from
	dbo.order_header oh
	join dbo.edi_setups es
		on es.destination = oh.destination
	join dbo.part_inventory pi
		on pi.part = oh.blanket_part
	left join dbo.shipper s
		on s.id = oh.shipper
where
	oh.order_type = 'B'


GO
