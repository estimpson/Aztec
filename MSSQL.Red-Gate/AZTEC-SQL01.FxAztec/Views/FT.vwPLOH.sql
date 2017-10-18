SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FT].[vwPLOH]
as
select
	Part = object.part
,	Location = object.location
,	OnHand = sum(object.std_quantity)
,	Secured = min(isnull(location.secured_location, 'N'))
from
	dbo.object
	join dbo.location
		on object.location = location.code
where
	object.status in ('A', 'H')
	and object.type is null
group by
	object.part
,	object.location
GO
