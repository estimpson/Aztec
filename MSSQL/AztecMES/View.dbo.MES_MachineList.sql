
/*
Create table fx21st.dbo.MES_MachineList
*/

--use fx21st
--go

--drop table dbo.MES_MachineList
if	objectproperty(object_id('dbo.MES_MachineList'), 'IsView') = 1 begin
	drop view dbo.MES_MachineList
end
go

create view dbo.MES_MachineList
as
select
	GroupTechnology = gt.id
,	MachineCode = m.machine_no
,   Description = m.mach_descp
,	Plant = l.plant
from
	dbo.machine m
	join dbo.location l
		on l.code = m.machine_no
	left join dbo.group_technology gt
		on gt.id = l.group_no
go

select
	mml.GroupTechnology
,	mml.MachineCode
,	mml.Description
,	mml.Plant
from
	dbo.MES_MachineList mml
