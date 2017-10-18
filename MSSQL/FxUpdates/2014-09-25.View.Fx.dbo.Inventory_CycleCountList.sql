
/*
Create View.Fx.dbo.Inventory_CycleCountList.sql
*/

--use Fx
--go

--drop table dbo.Inventory_CycleCountList
if	objectproperty(object_id('dbo.Inventory_CycleCountList'), 'IsView') = 1 begin
	drop view dbo.Inventory_CycleCountList
end
go

create view dbo.Inventory_CycleCountList
as
select
	Serial = o.serial
,   ParentSerial = o.parent_serial
,   PartCode = o.part
,   LocationCode = o.location
,   PlantCode = l.plant
,   StdQuantity = o.std_quantity
,   Unit = pi.standard_unit
from
	dbo.object o
	left join dbo.location l
		on o.location = l.code
	join dbo.part_inventory pi
		on pi.part = o.part
where
	o.shipper is null
go

select
	Inventory_CycleCountList.Serial
,   Inventory_CycleCountList.ParentSerial
,   Inventory_CycleCountList.PartCode
,   Inventory_CycleCountList.LocationCode
,   Inventory_CycleCountList.PlantCode
,   Inventory_CycleCountList.StdQuantity
,   Inventory_CycleCountList.Unit
from
	dbo.Inventory_CycleCountList
go

