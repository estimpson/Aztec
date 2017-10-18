
/*
Create view fx21st.dbo.MES_PartPackaging
*/

--use fx21st
--go

--drop table dbo.MES_PartPackaging
if	objectproperty(object_id('dbo.MES_PartPackaging'), 'IsView') = 1 begin
	drop view dbo.MES_PartPackaging
end
go

create view dbo.MES_PartPackaging
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
go

select
	*
from
	dbo.MES_PartPackaging
go
