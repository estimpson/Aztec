SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FT].[vwFirmOrders]
as
select
	FirmOrder
,   Source
,	Tool = ''
,   PartCode
,   RowNumber
,   FirmDueDT
,   FirmQty
,   PostAccum
from
	FT.vwFirmPOs vfpo
union all
select
	FirmOrder
,   Source
,   Tool
,   PartCode
,   RowNumber
,   FirmDueDT
,   FirmQty
,   PostAccum
from
	FT.vwFirmWOs vfwo
GO
