SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[vwPartStandardAccum]
as
select
	vps.Part
,	Cost = vps.Material + vps.Labor + vps.Burden
,	vps.Material
,	vps.Labor
,	vps.Burden
,	CostAccum =
		convert(numeric(20, 6), sum(xr.XQty * vpsChild.Material)) +
		convert(numeric(20, 6), sum(xr.XQty * vpsChild.Labor)) +
		convert(numeric(20, 6), sum(xr.XQty * vpsChild.Burden))
,	MaterialAccum = convert(numeric(20, 6), sum(xr.XQty * vpsChild.Material))
,	LaborAccum = convert(numeric(20, 6), sum(xr.XQty * vpsChild.Labor))
,	BurdenAccum = convert(numeric(20, 6), sum(xr.XQty * vpsChild.Burden))
from
	dbo.vwPartStandard vps
	join FT.XRt xr
		on vps.Part = xr.TopPart
	join vwPartStandard vpsChild
		on xr.ChildPart = vpsChild.Part
group by
	vps.Part
,	vps.Material
,	vps.Burden
,	vps.Labor

GO
