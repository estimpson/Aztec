SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[TransportDeliveryRequirements_Mfg]
as
select
	SalesOrder = ohMfg.order_no
,	DueDT = coalesce(tdBest.ScheduledDepartureDT, odDist.due_date)
,	OrderType = case odDist.type when 'F' then 0 when 'P' then 1 else 2 end
,	PartNumber = max(ohMfg.blanket_part)
,	OrderQuantity = sum(odDist.std_qty)
from
	dbo.order_detail odDist
	join dbo.order_header ohMfg
		on ohMfg.destination = odDist.plant
		and ohMfg.blanket_part = odDist.part_number
	left join dbo.TransportDeliveries tdBest
		on convert(varchar(23), tdBest.ScheduledArrivalDT, 121) + tdBest.DeliveryNumber =
			(	select
					max(convert(varchar(23), tdLast.ScheduledArrivalDT, 121) + tdLast.DeliveryNumber)
				from
					dbo.TransportDeliveries tdLast
				where
					tdLast.ArrivalPlant = odDist.plant
					and tdLast.ScheduledArrivalDT <= odDist.due_date
					and tdLast.DeparturePlant = ohMfg.plant                          
					and tdLast.Status = 0
			)
--where
--	odDist.plant = 'VTMI'
group by
	ohMfg.order_no
,	coalesce(tdBest.ScheduledDepartureDT, odDist.due_date)
,	case odDist.type when 'F' then 0 when 'P' then 1 else 2 end
GO
