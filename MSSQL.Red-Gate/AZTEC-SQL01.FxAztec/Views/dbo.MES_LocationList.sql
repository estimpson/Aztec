SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[MES_LocationList]
as
select
	LocationCode = l.code
,	Description = l.name
,	IsMachine = convert(bit, case when l.type = 'MC' then 1 else 0 end)
,	DepartmentCode = l.group_no
,	DepartmentDescription = gt.notes
,	BackflushSequence = coalesce(l.sequence, 0)
,	PlantCode = l.plant
,	PlantDescription = d.name
,	IsInventoryAvailable = convert(bit, case when l.secured_location = 'N' then 0 else 1 end)
from
	dbo.location l
	left join dbo.group_technology gt
		on gt.id = l.group_no
	left join dbo.destination d
		on d.destination = l.plant
GO
