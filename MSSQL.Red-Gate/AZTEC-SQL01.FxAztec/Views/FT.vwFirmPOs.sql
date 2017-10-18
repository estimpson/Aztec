SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FT].[vwFirmPOs]
as
with POs
(	FirmOrder, Source, PartCode, FirmDueDT, FirmQty, RowNumber)
as
(	select
		FirmOrder = 'PO#:' + convert(varchar, PONumber)
	,	Source = 'Vendor:' + VendorCode
	,	PartCode = Part
	,	FirmDueDT = DueDT
	,	FirmQty = StdQty
	,	RowNumber = row_number() over (partition by Part order by DueDT)
	from
		FT.vwPOD vp
	where
		StdQty > 0 and
		DueDT between getdate() - 7 and getdate() + LeadDays
	)
select
	FirmOrder
,   Source
,   PartCode
,	RowNumber
,   FirmDueDT
,   FirmQty
,   PostAccum = (select sum(FirmQty) from POs where PartCode = po.PartCode and RowNumber <= po.RowNumber)
from
	POs po
GO
