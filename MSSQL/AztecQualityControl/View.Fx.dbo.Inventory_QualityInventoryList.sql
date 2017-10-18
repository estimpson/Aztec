
/*
Create View.Fx.dbo.Inventory_QualityInventoryList.sql
*/

--use Fx
--go

--drop table dbo.Inventory_QualityInventoryList
if	objectproperty(object_id('dbo.Inventory_QualityInventoryList'), 'IsView') = 1 begin
	drop view dbo.Inventory_QualityInventoryList
end
go

create view dbo.Inventory_QualityInventoryList
as
select
	objectOrigin.Serial
,	objectOrigin.PartCode
,	objectOrigin.LocationCode
,	objectOrigin.PlantCode
,	objectOrigin.StandardQty
,	objectOrigin.StandardUnit
,	objectOrigin.Lot
,	objectOrigin.ShipperID
,	objectOrigin.OriginDT
,	objectOrigin.OriginType
from
	(	select
			Serial = oActive.serial
		,	PartCode = oActive.part
		,	LocationCode = oActive.location
		,	PlantCode = l.plant
		,	StandardQty = oActive.std_quantity
		,	StandardUnit = pi.standard_unit
		,	Lot = atCreate.lot
		,	ShipperID = atCreate.shipper
		,	OriginDT = atCreate.date_stamp
		,	OriginType = atCreate.remarks
		,	RowNumber = row_number() over (partition by oActive.serial order by atCreate.date_stamp)
		from
			dbo.object oActive
			left join dbo.Inventory_ObjectSource ios
				on ios.ObjectSerial = oActive.serial
			left join dbo.audit_trail atCreate
				on atCreate.serial = coalesce(ios.FromSerial, oActive.serial)
			left join dbo.location l
				on oActive.location = l.code
			join dbo.part_inventory pi
				on pi.part = oActive.part
		where
			oActive.std_quantity > 0
			and oActive.location != 'PRE-OBJECT'
	) objectOrigin
where
	RowNumber = 1
go

select
	*
from
	dbo.Inventory_QualityInventoryList iqil
go

