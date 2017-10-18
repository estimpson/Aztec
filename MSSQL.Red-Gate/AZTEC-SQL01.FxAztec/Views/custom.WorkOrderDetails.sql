SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [custom].[WorkOrderDetails]
as
select
	WOs.WorkOrderNumber
,	Line = row_number() over (partition by WOs.WorkOrderNumber order by Reqs.DueDT)
,	Status = 0
,	Type = 0
,	ProcessCode = convert(varchar(25), null)
,	TopPartCode = convert(varchar(50), null)
,	WOs.PartCode
,	Sequence = row_number() over (partition by WOs.WorkOrderNumber order by Reqs.DueDT)
,	Reqs.DueDT
,	Reqs.QtyRequired
,	QtyLabelled = 0.0
,	QtyCompleted = 0.0
,	QtyDefect = 0.0
,	QtyRework = 0.0
,	WOs.SetupHours
,	WOs.PartsPerHour
,	WOs.PartsPerCycle
,	WOs.CycleSeconds
,	WOs.StartDT
,	WOs.EndDT
,	Reqs.ShipperID
,	Reqs.SalesOrderNumber
,	Reqs.DestinationCode
,	Reqs.CustomerCode
,	Notes = convert(varchar(1000), null)
,	RowID = -row_number() over (order by WOs.WorkOrderNumber, Reqs.DueDT)
,	RowCreateDT = getdate()
,	RowCreateUser = suser_name()
,	RowModifiedDT = getdate()
,	RowModifiedUser = suser_name()
from
	(	select
			WorkOrderNumber = 'xWO_' + convert(varchar, getdate(), 112) + right('0000' +
				convert
				(	varchar
				,	row_number() over (order by pm.part, pm.machine)
				), 4)
		,	PartCode = pm.part
		,	SetupHours = pm.setup_time
		,	PartsPerHour = pm.parts_per_hour
		,	PartsPerCycle = pm.parts_per_cycle
		,	CycleSeconds = pm.cycle_time
		,	StartDT = convert(datetime, null)
		,	EndDT = convert(datetime, null)
		from
			dbo.part_machine pm
	) WOs
	left join
	(	select
			ShipperID = s.id
		,	PartCode = sd.part_original
		,	DueDT = s.date_stamp
		,	QtyRequired = sd.qty_required - coalesce(sd.qty_packed, 0)
		,	SalesOrderNumber = sd.order_no
		,	DestinationCode = s.destination
		,	CustomerCode = s.customer
		from
			dbo.shipper s
			join dbo.shipper_detail sd
				on sd.shipper = s.id
		where
			s.status in ('O', 'A', 'S')
			and coalesce(s.type, 'N') = 'N'
	) Reqs
		on Reqs.PartCode = WOs.PartCode
GO
