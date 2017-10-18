SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [ChryslerEDI].[BlanketOrders]
as
select
	BlanketOrderNo = oh.order_no
,	ShipToCode = oh.destination
,	EDIShipToCode = coalesce(es.parent_destination, oh.destination)
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
,	Returnable = case when pm.returnable = 'Y' then 'Y' else 'N' end
,	UnitWeight = pi.unit_weight
,	AccumShipped = oh.our_cum
,	ProcessReleases = case when coalesce(es.release_flag, 'P') = 'F' then 1 else 0 end
,	ECL = oh.engineering_level
,	DockCode = oh.dock_code
,	Clause092UnitCost = case when isnumeric(oh.notes) = 1 then convert(numeric(10,6), oh.notes) else 0.000000 end
from
	dbo.order_header oh
	join dbo.edi_setups es
		on es.destination = oh.destination
	join dbo.part_inventory pi
		on pi.part = oh.blanket_part
	join dbo.package_materials pm
		on pm.code = oh.package_type
	left join dbo.shipper s
		on s.id = oh.shipper
where
	oh.order_type = 'B'
	and es.asn_overlay_group like ('CH%')
GO
