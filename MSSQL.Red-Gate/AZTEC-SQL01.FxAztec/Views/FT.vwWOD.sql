SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FT].[vwWOD]
(	WorkOrder,
	MachineCode,
	ToolCode,
	Part,
	DueDT,
	LineID,
	StdQty
)
as
--	Description:
--	Get open purchase order details (must be an updateable view).
select
	WorkOrder = wod.WorkOrderNumber,
	MachineCode = woh.MachineCode,
	ToolCode = woh.ToolCode,
	Part = wod.PartCode,
	DueDT = wod.DueDT,
	LineID = woh.Sequence,
	StdQty = wod.QtyRequired - wod.QtyCompleted
from
	dbo.WorkOrderDetails wod
	join dbo.WorkOrderHeaders woh on
		wod.WorkOrderNumber = woh.WorkOrderNumber
where
	wod.QtyRequired - wod.QtyCompleted >= 0
GO
