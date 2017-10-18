SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[vwMachineStateExt]
as
select
	MachineCode = m.machine_no
,	Description = m.mach_descp
,	GroupTechnology = l.group_no
,	MachineStatus = ms.Type
,	OperatorCode = ms.OperatorCode
,	OperatorName = (select name from dbo.employee where operator_code = ms.OperatorCode)
,	ms.ActiveWorkOrderNumber
,	ms.ActiveWorkOrderDetailSequence
,	JobStatus = woh.Status
,	TopPartCode = wod.TopPartCode
,	PartCode = wod.PartCode
,	JobDescription = convert (varchar(4000),
		'Part: ' + wod.PartCode
		+ coalesce ('  SID: ' + convert (varchar, wod.ShipperID), '')
		+ coalesce ('  SOID: ' + convert (varchar, wod.SalesOrderNumber), '')
		+ coalesce ('  ShipTo: ' + wod.DestinationCode, '')
		+ coalesce ('  BillTo: ' + wod.CustomerCode, '')
	)
,	CurrentPalletSerial = ms.CurrentPalletSerial
,	RequiredQty = wod.QtyRequired
,	ProducedQty = wod.QtyCompleted
,	BuildableQty = convert (numeric(20,6), null)
,	DefectQty = wod.QtyDefect
,	ReworkedQty = convert (numeric(20,6), null)
,	MaterialLots = convert (varchar(max), null)
,	JobSetupTime = convert (float, 0)
,	JobRunTime = convert (float, 0)
,	JobDownTime = convert (float, 0)
,	ActualStartDT = convert (datetime, null)
,	EstimatedCompletionDT = convert (datetime, null)
,	DueDT = convert (datetime, null)
,	ShiftBeginDT = convert (datetime, null)
,	ShiftEndDT = convert (datetime, null)
,	AccumulatedSetupTime = convert (float, 0)
,	AccumulatedRunTime = convert (float, 0)
,	AccumulatedDownTime = convert (float, 0)
,	AccumulatedUnscheduledTime = convert (float, 0)
from
	dbo.machine m
	join dbo.location l on
		machine_no = l.code
	left join dbo.MachineState ms on
		m.machine_no = ms.MachineCode
	left join dbo.WorkOrderHeaders woh on
		ms.ActiveWorkOrderNumber = woh.WorkOrderNumber
	left join dbo.WorkOrderDetails wod on
		ms.ActiveWorkOrderNumber = wod.WorkOrderNumber
		and
			ms.ActiveWorkOrderDetailSequence = wod.Sequence
GO
