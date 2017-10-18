SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FT].[MenuUserAccess]
as
select
	xmi.MenuID
,	ApplicationName = mi.MenuItemName
,	xmi.MenuItemName
,	xmi.MenuIcon
,	xmi.MenuText
,	xmi.ObjectClass
,	xmi.ObjectType
,	xmi.Level
,	xmi.Sequence
,	xmi.Chain
,	u.OperatorCode
,	UserAccess = case when sa.Type = 0 then 1 else 0 end
from
	FT.XMenuItems xmi
	cross join FT.Users u
	left join FT.SecurityAccess sa
		on sa.ResourceID = xmi.MenuID
		and sa.SecurityID = u.UserID
	join FT.MenuItems mi
		on mi.MenuID = xmi.TopMenuID
GO
