SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [EDI3060].[BlanketOrders]
as
select
	BlanketOrderNo = oh.order_no
,	ShipToCode = oh.destination
,	EDIShipToCode = coalesce(nullif(es.EDIShipToID, ''), nullif(es.parent_destination, ''), es.destination)
,	ShipToConsignee = es.pool_code
,	SupplierCode = es.supplier_code
,	CustomerPart = oh.customer_part
,	CustomerPO = oh.customer_po
,	CheckCustomerPOPlanning = convert(bit, case coalesce(check_po, 'N')when 'Y' then 1 else 0 end)
,	CheckCustomerPOShipSchedule = coalesce(CheckCustomerPOFirm, 0)
,	ModelYear862 = coalesce(right(oh.model_year, 1), '')
,	ModelYear830 = coalesce(left(oh.model_year, 1), '')
,	CheckModelYearPlanning = convert(bit, case coalesce(check_model_year, 'N')when 'Y' then 1 else 0 end)
,	CheckModelYearShipSchedule = 0
,	PartCode = oh.blanket_part
,	OrderUnit = oh.shipping_unit
,	LastSID = oh.shipper
,	LastShipDT = s.date_shipped
,	LastShipQty =
		(	select
				max(qty_packed)
			from
				Fx.shipper_detail
			where
				shipper = oh.shipper
				and order_no = oh.order_no
		)
,	PackageType = oh.package_type
,	UnitWeight = pi.unit_weight
,	AccumShipped = oh.our_cum
,	RawCUM = oh.raw_cum
,	RawCUMDT = oh.raw_date
,	FabCUM = oh.fab_cum
,	FabCUMDT = oh.fab_date
,	ProcessReleases = coalesce(es.ProcessEDI, 1)
,	ActiveOrder = convert(bit, case when coalesce(order_status, '') = 'A' then 1 else 0 end)
,	ModelYear = oh.model_year
,	PlanningFlag = coalesce(es.PlanningReleasesFlag, 'A')
,	TransitDays = coalesce(es.TransitDays, 0)
,	ReleaseDueDTOffsetDays = coalesce(es.EDIOffsetDays, 0)
,	ReferenceAccum = coalesce(ReferenceAccum, 'O')
,	AdjustmentAccum = coalesce(AdjustmentAccum, 'C')
,	PlanningReleaseHorizonDaysBack = -1 * (coalesce(PlanningReleaseHorizonDaysBack, 30))
,	ShipScheduleHorizonDaysBack = -1 * (coalesce(ShipScheduleHorizonDaysBack, 30))
,	ProcessPlanningRelease = coalesce(es.ProcessPlanningRelease, 1)
,	ProcessShipSchedule = coalesce(es.ProcessShipSchedule, 1)
from
	Fx.order_header oh
	join Fx.edi_setups es
		join EDI.XML_ASNOverlayGroups_ProcessingDefinition xaogpd
			on xaogpd.ASNOverlayGroup = es.asn_overlay_group
			and xaogpd.ProcessingProcedureSchema = 'EDI3060'
		on es.destination = oh.destination
	left join Fx.part_inventory pi
		on pi.part = oh.blanket_part
	left join Fx.shipper s
		on s.id = oh.shipper
where
	oh.order_type = 'B'
	and coalesce(es.ProcessEDI, 1) = 1
GO
