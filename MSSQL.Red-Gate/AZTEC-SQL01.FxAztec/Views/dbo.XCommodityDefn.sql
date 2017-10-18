SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[XCommodityDefn] as
with DCommodityDefn
(	ParentCommodityID
,	DCount)
as
(	select
		ParentCommodityID
	,	DCount = Convert(float, count(*))--sum(DCount)
	from
		dbo.CommodityDefn cd
	group by
		ParentCommodityID),
XCommodityDefn
(	TopCommodityID
,	ParentCommodityID
,	CommodityID
,	CommodityCode
,	CommodityDescription
,	Virtual
,	Level
,	Sequence
,	SequenceGroupSize
,	Chain
,	DrAccount
,	iDrAccount)
as
(
--	Anchor
	select
		TopCommodityID = CommodityID
	,	ParentCommodityID
	,	CommodityID
	,   CommodityCode
	,   CommodityDescription
	,   Virtual
	,	Level = 0
	,	Sequence = convert (float, 0)
	,	SequenceGroupSize = convert (float, 1)
	,	Chain = convert (varchar(max), CommodityCode)
	,	DrAccount
	,	iDrAccount = convert (varchar(50), null)
	from
		dbo.CommodityDefn cd
--	where
--		ParentCommodityID is null
	union all
	select
		TopCommodityID = X.TopCommodityID
	,	cd.ParentCommodityID
	,	cd.CommodityID
	,	cd.CommodityCode
	,	cd.CommodityDescription
	,	cd.Virtual
	,	X.Level + 1
	,	Sequence + convert (float, row_number() over (order by cd.CommodityCode ASC)) * SequenceGroupSize / (D.DCount + 1.0)
	,	SequenceGroupSize / (D.DCount + 1.0)
	,	Chain = Chain + '\' + cd.CommodityCode
	,	DrAccount = cd.DrAccount
	,	iDrAccount = coalesce(X.DrAccount, X.iDrAccount)
	from
		XCommodityDefn X
		join dbo.CommodityDefn cd on
			X.CommodityID = cd.ParentCommodityID
		join DCommodityDefn D on
			coalesce(cd.ParentCommodityID, 0) = coalesce(D.ParentCommodityID,0)
)
select
	TopCommodityID
,	ParentCommodityID
,	CommodityID
,	CommodityCode
,	CommodityDescription
,	Virtual
,	Level
,	Sequence = (select count(1) from XCommodityDefn where TopCommodityID = xcd.TopCommodityID and Sequence < xcd.Sequence)
,	Chain
,	DrAccount
,	iDrAccount
from
	XCommodityDefn xcd
GO
