SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[MES_PartPackaging]
as
select
	PartCode = pp.part
,	PackageCode = pm.code
,	PackageDescription = pm.name
,	StandardPack = pp.quantity
,	PackagingType = pm.type
,	ReturnableType = pm.returnable
,	TareWeight = pm.weight
from
	dbo.part_packaging pp
	join dbo.package_materials pm
		on pm.code = pp.code
where
	pm.type in ('B', 'O')
GO
