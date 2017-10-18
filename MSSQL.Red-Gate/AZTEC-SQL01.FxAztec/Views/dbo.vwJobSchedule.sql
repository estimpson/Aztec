SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[vwJobSchedule]
as
with JobSchedule
(	WorkOrderNumber, Status, MachineCode, PlantCode, ToolCode, Sequence, SetupHours, Line, WorkOrderDetailSequence, PartCode, Balance, PartsPerHour, RunTime, PartsPerCycle, CyclesRemaining, CycleSeconds, DueDT, OrderNo, DestinationCode, CustomerCode, Notes
)
as
(
	select
		WorkOrderNumber = woh.WorkOrderNumber
	,	Status = woh.Status
	,	MachineCode = woh.MachineCode
	,	PlantCode = l.plant
	,	ToolCode = woh.ToolCode
	,	Sequence = woh.Sequence
	,	SetupHours = wod.SetupHours
	,	Line = wod.Line
	,	WorkOrderDetailSequence = wod.Sequence
	,	PartCode = wod.PartCode
	,	Balance = wod.QtyRequired - wod.QtyCompleted
	,	PartsPerHour = wod.PartsPerHour
	,	RunTime = (wod.QtyRequired - wod.QtyCompleted) / nullif (wod.PartsPerHour, 0)
	,	PartsPerCycle = wod.PartsPerCycle
	,	CyclesRemaining = (wod.QtyRequired - wod.QtyCompleted) / nullif (wod.PartsPerCycle, 0)
	,	CycleSeconds = 3600.0 * wod.PartsPerCycle / nullif (wod.PartsPerHour, 0)
	,	DueDT = wod.DueDT
	,	OrderNo = wod.SalesOrderNumber
	,	DestinationCode = wod.DestinationCode
	,	CustomerCode = wod.CustomerCode
	,	Notes = wod.Notes
	from
		dbo.WorkOrderHeaders woh
		join dbo.WorkOrderDetails wod on
			woh.WorkOrderNumber = wod.WorkOrderNumber
		join dbo.location l on
			woh.MachineCode = l.code
	where
		woh.Sequence >= 0
)
select
	WorkOrderNumber
,	Status
,	MachineCode
,	PlantCode
,	ToolCode
,	Sequence
,	SetupHours
,	Line
,	WorkOrderDetailSequence
,	PartCode
,	Balance
,	PartsPerHour
,	RunTime
,	PartsPerCycle
,	CyclesRemaining
,	CycleSeconds
,	DueDT
,	StartDT = dateadd (s, coalesce ((select sum (SetupHours + RunTime) * 3600.0 from JobSchedule where MachineCode = js.MachineCode and Sequence < js.Sequence), 0), getdate())
,	EndDT = dateadd (s, coalesce ((select sum (SetupHours + RunTime) * 3600.0 from JobSchedule where MachineCode = js.MachineCode and Sequence <= js.Sequence), 0), getdate())
,	OrderNo
,	DestinationCode
,	CustomerCode
,	Notes
from
	JobSchedule js
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[trJobSchedule_iud] on [dbo].[vwJobSchedule]
instead of insert, update, delete
as

/*	Change to job details. */
update
	dbo.WorkOrderDetails
set
	QtyRequired = QtyRequired + i.Balance - d.Balance
,	PartsPerHour =
	case
		when update(PartsPerHour) then i.PartsPerHour
		else coalesce(3600.0 * nullif(i.PartsPerCycle, d.PartsPerCycle) / nullif(i.CycleSeconds, 0), i.PartsPerHour)
	end
,	PartsPerCycle = i.PartsPerCycle
,	CycleSeconds =
	case
		when update(CycleSeconds) then i.CycleSeconds
		else coalesce(3600.0 * i.PartsPerCycle / nullif(i.PartsPerHour, 0), i.CycleSeconds)
	end
,	DueDT = i.DueDT
,	SetupHours = i.SetupHours
,	Notes = i.Notes
from
	dbo.WorkOrderDetails wod
	join inserted i on
		wod.WorkOrderNumber = i.WorkOrderNumber
		and
			wod.Line = i.Line
	join deleted d on
		i.WorkOrderNumber = d.WorkOrderNumber
		and
			i.Line = d.Line

/*	Job header changes. */
update
	dbo.WorkOrderHeaders
set
	DueDT = (select min(DueDT) from dbo.WorkOrderDetails where WorkOrderNumber = woh.WorkOrderNumber)
,	ToolCode = i.ToolCode
from
	dbo.WorkOrderHeaders woh
	join inserted i on
		woh.WorkOrderNumber = i.WorkOrderNumber
	join deleted d on
		i.WorkOrderNumber = d.WorkOrderNumber

/*	Sequence changes where machine didn't change */
update
	dbo.WorkOrderHeaders
set
	Sequence = i.Sequence
from
	dbo.WorkOrderHeaders woh
	join inserted i on
		woh.WorkOrderNumber = i.WorkOrderNumber
	join deleted d on
		i.WorkOrderNumber = d.WorkOrderNumber
where
	i.MachineCode = d.MachineCode

/*	Move a job to a new machine. */
update
	dbo.WorkOrderHeaders
set
	MachineCode = i.MachineCode
,	Sequence = coalesce
	(
		(
			select
				max(Sequence) + 1
			from
				dbo.WorkOrderHeaders
			where
				MachineCode = woh.MachineCode
		)
	,	1
	)
from
	dbo.WorkOrderHeaders woh
	join inserted i on
		woh.WorkOrderNumber = i.WorkOrderNumber
	join deleted d on
		i.WorkOrderNumber = d.WorkOrderNumber
where
	i.MachineCode != d.MachineCode

update
	dbo.WorkOrderHeaders
set
	Sequence = woh.Sequence - 1
from
	dbo.WorkOrderHeaders woh
	join deleted d on
		woh.MachineCode = d.MachineCode
		and
			woh.Sequence > d.Sequence
	join inserted i on
		d.WorkOrderNumber = i.WorkOrderNumber
where
	i.MachineCode != d.MachineCode

/*	Deletes and inserts not allowed.  */
GO
