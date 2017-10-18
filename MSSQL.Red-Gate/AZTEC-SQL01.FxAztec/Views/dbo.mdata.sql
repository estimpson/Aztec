SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[mdata]
as
select
	pmcode = coalesce(nullif(left(Chain, len(Chain) - 2), ''), '00')
,	mcode = Chain
,	mname = MenuItemName
,	switch = 'N'
,	display = 'Y'
,	menuName = MenuText
,	menuIcon = MenuIcon
,	objectName = xmi.ObjectClass
,	objectType = xmi.ObjectType
from
	FT.XMenuItems xmi
GO
