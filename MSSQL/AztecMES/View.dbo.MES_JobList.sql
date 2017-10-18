
/*
Create view fx21st.dbo.MES_JobList
*/

--use fx21st
--go

--drop table dbo.MES_JobList
if	objectproperty(object_id('dbo.MES_JobList'), 'IsView') = 1 begin
	drop view dbo.MES_JobList
end
go

create view dbo.MES_JobList
as
select
	WODID = wod.RowID
,	WorkOrderNumber = woh.WorkOrderNumber
,	WorkOrderStatus = woh.Status
,	WorkOrderType = woh.Type
,	MachineCode = woh.MachineCode
,	WorkOrderDetailLine = wod.Line
,	WorkOrderDetailStatus = wod.Status
,	wod.PartCode
,	WorkOrderDetailSequence = wod.Sequence
,	DueDT = wod.DueDT
,	QtyRequired = wod.QtyRequired
,	QtyLabelled = wod.QtyLabelled
,	QtyCompleted = wod.QtyCompleted
,	QtyDefect = wod.QtyDefect
,	PackageType = pp.code
,	StandardPack = coalesce(pp.quantity, oh.standard_pack, pi.standard_pack) --Use the order's standard pack, the default standard pack for the package type, or the standard pack for the part.
,	NewBoxesRequired = case when wod.QtyRequired > wod.QtyLabelled then ceiling((wod.QtyRequired - wod.QtyLabelled) / coalesce(pp.quantity, oh.standard_pack, pi.standard_pack)) else 0 end
,	BoxLabelFormat = coalesce(od.box_label, oh.box_label, pp.label_format, pi.label_format)
,	BoxesLabelled = coalesce(boxes.BoxesLabelled, 0)
,	BoxesCompleted = coalesce(boxes.BoxesCompleted, 0)
,	BoxesCompletedNotPutaway = coalesce(boxes.BoxesCompletedNotPutAway, 0)
,	StartDT = wod.StartDT
,	EndDT = wod.EndDT
,	ShipperID = wod.ShipperID
,	BillToCode = wod.CustomerCode
from
	(	
		select
			WorkOrderNumber = coalesce(woh.WorkOrderNumber, woh2.WorkOrderNumber)
		,	Status = coalesce(woh.Status, woh2.Status)
		,	Type = coalesce(woh.Type, woh2.Type)
		,	MachineCode = coalesce(woh.MachineCode, woh2.MachineCode)
		,	ToolCode = coalesce(woh.ToolCode, woh2.ToolCode)
		,	Sequence = coalesce(woh.Sequence, woh2.Sequence)
		,	DueDT = coalesce(woh.DueDT, woh2.DueDT)
		,	ScheduledSetupHours = coalesce(woh.ScheduledSetupHours, woh2.ScheduledSetupHours)
		,	ScheduledStartDT = coalesce(woh.ScheduledStartDT, woh2.ScheduledStartDT)
		,	ScheduledEndDT = coalesce(woh.ScheduledEndDT, woh2.ScheduledEndDT)
		,	RowID = coalesce(woh.RowID, woh2.RowID)
		from
			dbo.WorkOrderHeaders woh
			full join custom.WorkOrderHeaders woh2
				on woh2.WorkOrderNumber = woh.WorkOrderNumber
	) woh
		join
		(
			select
					WorkOrderNumber = coalesce(wod.WorkOrderNumber, wod2.WorkOrderNumber)
				,	Line = coalesce(wod.Line, wod2.Line)
				,	Status = coalesce(wod.Status, wod2.Status)
				,	Type = coalesce(wod.Type, wod2.Type)
				,	PartCode = coalesce(wod.PartCode, wod2.PartCode)
				,	Sequence = coalesce(wod.Sequence, wod2.Sequence)
				,	SetupHours = coalesce(wod.SetupHours, wod2.SetupHours)
				,	PartsPerHour = coalesce(wod.PartsPerHour, wod2.PartsPerHour)
				,	PartsPerCycle = coalesce(wod.PartsPerCycle, wod2.PartsPerCycle)
				,	CycleSecons = coalesce(wod.CycleSeconds, wod2.CycleSeconds)
				,	DueDT = coalesce(wod.DueDT, wod2.DueDT)
				,	QtyRequired = coalesce(wod.QtyRequired, wod2.QtyRequired)
				,	QtyLabelled = coalesce(wod.QtyLabelled, wod2.QtyLabelled)
				,	QtyCompleted = coalesce(wod.QtyCompleted, wod2.QtyCompleted)
				,	QtyDefect = coalesce(wod.QtyDefect, wod2.QtyDefect)
				,	StartDT = coalesce(wod.StartDT, wod2.StartDT)
				,	EndDT = coalesce(wod.EndDT, wod2.EndDT)
				,	ShipperID = coalesce(wod.ShipperID, wod2.ShipperID)
				,	SalesOrderNumber = coalesce(wod.SalesOrderNumber, wod2.SalesOrderNumber)
				,	CustomerCode = coalesce(wod.CustomerCode, wod2.CustomerCode)
				,	RowID = coalesce(wod.RowID, wod2.RowID)
			from
				dbo.WorkOrderDetails wod
				full join custom.WorkOrderDetails wod2
					on wod.WorkOrderNumber = wod2.WorkOrderNumber
					and wod.Line = wod2.Line
		) wod
			on wod.WorkOrderNumber = woh.WorkOrderNumber
		left join dbo.order_header oh
			on oh.order_no = wod.SalesOrderNumber 
		left join dbo.order_detail od
			on od.id =
			(	select
					min(od1.id)
				from
					dbo.order_detail od1
				where
					od1.order_no = wod.SalesOrderNumber
					and od1.part_number = wod.PartCode
			)
		left join
		(	select
				woo.WorkOrderNumber
			,	woo.WorkOrderDetailLine
			,	BoxesLabelled = count(*)
			,	BoxesCompleted = count(woo.CompletionDT)
			,	PackageType = min(woo.PackageType)
			,	BoxesCompletedNotPutAway = count(case when o.serial is not null then woo.CompletionDT end)
			from
				dbo.WorkOrderObjects woo
				left join dbo.object o
					join dbo.machine m
						on o.location = m.machine_no
					on o.serial = woo.Serial
			group by
				woo.WorkOrderNumber
			,	woo.WorkOrderDetailLine
		) boxes
			on boxes.WorkOrderNumber = wod.WorkOrderNumber
			and boxes.WorkOrderDetailLine = wod.Line
	join dbo.part_inventory pi
		on wod.PartCode = pi.part
/*	Get the package type by precedence:
		1. Boxes already labelled
		2. Order's specified package type
		3. Correct package type for the order's standard pack.
		4. Correct package type for the part's standard pack.
*/
	left join dbo.part_packaging pp
		on pp.part = wod.PartCode
		and pp.code = coalesce
		(	boxes.PackageType
		,	oh.package_type
		,	(	select
					min(code)
				from
					dbo.part_packaging pp2
				where
					pp2.part = wod.PartCode
					and
					(	pp2.code = boxes.PackageType
						or pp2.quantity = coalesce(oh.standard_pack, pi.standard_pack)
					)
			)
		)
where
	woh.Status in
	(	select
			sd.StatusCode
		from
			FT.StatusDefn sd
		where
			sd.StatusTable = 'dbo.WorkOrderHeaders'
			and sd.StatusName in ('Open', 'Hold', 'New', 'Running')
	 )
	 and wod.Status in
	 (	select
	 		sd.StatusCode
	 	from
	 		FT.StatusDefn sd
	 	where
	 		sd.StatusTable = 'dbo.WorkOrderDetails'
			and sd.StatusName in ('Open', 'Hold', 'New', 'Running')
	 )
go

select
	*
from
	dbo.MES_JobList
