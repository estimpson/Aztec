SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [FT].[XMenuItems]
as
with DMenuItems
(	ParentMenuID
,	DCount)
as
(	select
		ParentMenuID
	,	DCount = Convert(float, count(*))--sum(DCount)
	from
		FT.MenuStructure ms
	group by
		ParentMenuID
),
XMenuItems
(	TopMenuID
,	ParentMenuID
,	MenuID
,	MenuItemName
,	MenuIcon
,	MenuText
,	ObjectClass
,	ObjectType
,	Level
,	Sequence
,	SequenceGroupSize
,	Chain
)
as
(
--	Anchor
	select
		TopMenuID = mi.MenuID
	,	ParentMenuID
	,	MenuID
	,	mi.MenuItemName
	,	mi.MenuIcon
	,	mi.MenuText
	,	mi.ObjectClass
	,	ObjectType = dbo.udf_TypeName('FT.MenuItems', mi.Type)
	,	Level = 0
	,	Sequence = convert (float, 0)
	,	SequenceGroupSize = convert (float, 1)
	,	Chain = convert (varchar(max), right('0' + convert (varchar, row_number() over (order by ms2.Sequence ASC)), 2))
	from
		FT.MenuItems mi
		left join FT.MenuStructure ms2 on
			mi.MenuID = ms2.ChildMenuID
	where
		ms2.ParentMenuID is null
		and mi.Status >= 0      
	union all
	select
		TopMenuID = X.TopMenuID
	,	ms3.ParentMenuID
	,	mi2.MenuID
	,	mi2.MenuItemName
	,	mi2.MenuIcon
	,	mi2.MenuText
	,	mi2.ObjectClass
	,	ObjectType = dbo.udf_TypeName('FT.MenuItems', mi2.Type)
	,	X.Level + 1
	,	X.Sequence + convert (float, row_number() over (order by ms3.Sequence ASC)) * SequenceGroupSize / (D.DCount + 1.0)
	,	SequenceGroupSize / (D.DCount + 1.0)
	,	Chain = Chain + right('0' + convert (varchar, row_number() over (order by ms3.Sequence ASC)), 2)
	from
		XMenuItems X
		join FT.MenuStructure ms3 on
			X.MenuID = ms3.ParentMenuID
		join FT.MenuItems mi2 on
			ms3.ChildMenuID = mi2.MenuID
            and mi2.Status >= 0
		join DMenuItems D on
			ms3.ParentMenuID = D.ParentMenuID
			or
				ms3.ParentMenuID is null and D.ParentMenuID is null
)
select
	TopMenuID
,	ParentMenuID
,	MenuID
,	MenuItemName
,	MenuIcon
,	MenuText
,	ObjectClass
,	ObjectType
,	Level
,	Sequence = (select count(1) from XMenuItems where TopMenuID = xmi.TopMenuID and Sequence < xmi.Sequence)
,	Chain
from
	XMenuItems xmi

GO
