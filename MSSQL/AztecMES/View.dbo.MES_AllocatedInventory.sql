
/*
Create view fx21st.dbo.MES_AllocatedInventory
*/

--use fx21st
--go

--drop table dbo.MES_AllocatedInventory
if	objectproperty(object_id('dbo.MES_AllocatedInventory'), 'IsView') = 1 begin
	drop view dbo.MES_AllocatedInventory
end
go

create view dbo.MES_AllocatedInventory
as
select
	oAvailable.PartCode
,	AvailableToMachine = coalesce(lGroupMachines.code, msl.MachineCode, oAvailable.LocationCode)
,	oAvailable.QtyAvailable
from
	(	select
			PartCode = o.part
		,	LocationCode = o.location
		,	QtyAvailable = sum(o.std_quantity)
		from
			dbo.object o
		where
			o.status = 'A'
		group by
			o.part
		,	o.location
	) oAvailable
	left join dbo.MES_SetupBackflushingPrinciples msbp
		on msbp.Type = 3
		and msbp.ID = oAvailable.PartCode
	left join dbo.MES_StagingLocations msl
		on msbp.BackflushingPrinciple = 3 --StagingLocation
		and msl.PartCode = oAvailable.PartCode
		and msl.StagingLocationCode = oAvailable.LocationCode
	left join dbo.location lGroupTechActive
		join dbo.location lGroupMachines
			on lGroupTechActive.group_no = lGroupMachines.group_no
		on msbp.BackflushingPrinciple = 4 --GroupTechnology (sequence)
		and lGroupTechActive.code = oAvailable.LocationCode
		and lGroupTechActive.sequence > 0
	join dbo.machine m
		on m.machine_no = coalesce(lGroupMachines.code, msl.MachineCode, oAvailable.LocationCode)
go

