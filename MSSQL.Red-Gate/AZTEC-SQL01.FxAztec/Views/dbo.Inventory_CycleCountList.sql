SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[Inventory_CycleCountList]
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
GO
