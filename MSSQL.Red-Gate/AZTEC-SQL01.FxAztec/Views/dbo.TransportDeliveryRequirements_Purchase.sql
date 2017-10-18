SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[TransportDeliveryRequirements_Purchase]
as
select
	PurchaseOrder = ph.PONumber
,	DueDT = coalesce(tdBest.ScheduledDepartureDT, fgpn.RequiredDT)
,	PartNumber = fgpn.Part
,	OrderQuantity = sum(fgpn.Balance)
,	Plant = fgpn.Plant
from
	dbo.fn_GetPlantNetout(null) fgpn
	join dbo.part pRaw
		on pRaw.type = 'R'
		and pRaw.part = fgpn.Part
	left join
		(	select
				ph.blanket_part
			,	ph.ship_to_destination
			,	ph.plant
			,	PONumber = max(ph.po_number)
			from
				dbo.po_header ph
				left join dbo.part_online po
					on po.part = ph.blanket_part
			where
				ph.status = 'A'
				and ph.vendor_code = coalesce(nullif(po.default_vendor, ''), ph.vendor_code)
				and ph.po_number = coalesce(nullif(po.default_po_number, 0), ph.po_number)
			group by
				ph.blanket_part
			,	ph.ship_to_destination
			,	ph.plant          
		) ph
		on ph.plant = fgpn.Plant
		and ph.blanket_part = fgpn.Part
	left join dbo.TransportDeliveries tdBest
		on convert(varchar(23), tdBest.ScheduledArrivalDT, 121) + tdBest.DeliveryNumber =
			(	select
					max(convert(varchar(23), tdLast.ScheduledArrivalDT, 121) + tdLast.DeliveryNumber)
				from
					dbo.TransportDeliveries tdLast
				where
					tdLast.ArrivalPlant = ph.Plant
					and tdLast.ScheduledArrivalDT <= fgpn.RequiredDT
					and tdLast.DeparturePlant = ph.ship_to_destination                 
					and tdLast.Status = 0
			)
where
	fgpn.Balance > 0
group by
	ph.PONumber
,	fgpn.Part
,	fgpn.Plant
,	coalesce(tdBest.ScheduledDepartureDT, fgpn.RequiredDT)

GO
