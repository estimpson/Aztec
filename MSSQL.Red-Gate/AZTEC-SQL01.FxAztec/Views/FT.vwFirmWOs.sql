SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FT].[vwFirmWOs]
as
with WOs
(	FirmOrder, Source, Tool, PartCode, FirmDueDT, FirmQty, RowNumber)
as
(	select
		FirmOrder = 'WO#:' + convert(varchar, WorkOrder)
	,	Source = 'Machine:' + MachineCode
	,	Tool = coalesce ('Tool:' + nullif (ToolCode, ''), '')
	,	PartCode = Part
	,	FirmDueDT = DueDT
	,	FirmQty = StdQty
	,	RowNumber = row_number() over (partition by Part order by DueDT)
	from
		FT.vwWOD wd
	where
		StdQty > 0
	)
select
	FirmOrder
,   Source
,	Tool
,   PartCode
,	RowNumber
,   FirmDueDT
,   FirmQty
,   PostAccum = (select sum(FirmQty) from WOs where PartCode = wo.PartCode and RowNumber <= wo.RowNumber)
from
	WOs wo
GO
