SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[Inventory_QualityInventoryList]
as
select
	objectOrigin.Serial
,	objectOrigin.ParentSerial
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
		,	ParentSerial = oActive.parent_serial
		,	PartCode = oActive.part
		,	LocationCode = oActive.location
		,	PlantCode = l.plant
		,	StandardQty = oActive.std_quantity
		,	StandardUnit = pi.standard_unit
		,	Lot = atCreate.lot
		,	ShipperID = atCreate.shipper
		,	OriginDT = atCreate.date_stamp
		,	OriginType = atCreate.remarks
		,	RowNumber = row_number() over (partition by atCreate.serial order by atCreate.date_stamp)
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
	) objectOrigin
where
	RowNumber = 1
GO
