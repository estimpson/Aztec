SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [FT].[vwBOM]
(	BOMID
,	ParentPart
,	ChildPart
,	StdQty
,	ScrapFactor
,	SubstitutePart
)
as
--	Description:
--	Use bill_of_material view because it only pulls current records.
select
	BOMID = id
,	ParentPart = parent_part
,	ChildPart = part
,	StdQty = std_qty
,	ScrapFactor = scrap_factor
,	SubstitutePart = convert (bit, case when coalesce(substitute_part, 'N') = 'Y' then 1 else 0 end)
from
	dbo.bill_of_material
where
	IsNull (std_qty, 0) > 0
GO
