

/*
--drop index dbo.audit_trail.ix_audit_trail_origin
create index ix_audit_trail_origin on dbo.audit_trail (type, serial, date_stamp, id) include (from_loc, std_quantity, remarks, lot, shipper)
*/

/*
Create view Fx.dbo.Inventory_BreakOutHistory
*/

--use Fx
--go

--drop table dbo.Inventory_BreakOutHistory
if	objectproperty(object_id('dbo.Inventory_BreakOutHistory'), 'IsView') = 1 begin
	drop view dbo.Inventory_BreakOutHistory
end
go

create view dbo.Inventory_BreakOutHistory
as
select
	FromSerial = atBreakFrom.serial
,	TranDT = atBreakFrom.date_stamp
,	FromPartCode = atBreakFrom.part
,	ToSerial = atBreakTo.serial
,	Quantity = atBreakTo.std_quantity
from
	dbo.audit_trail atBreakFrom
	join dbo.audit_trail atBreakTo
		on atBreakTo.type = 'B'
		and atBreakTo.from_loc not like '%[^-0-9]%'
		and convert(int, atBreakTo.from_loc) = atBreakFrom.serial
		and datediff(second, atBreakTo.date_stamp, atBreakFrom.date_stamp) between 0 and 10
where
	atBreakFrom.type = 'B'
go

select
	*
from
	dbo.Inventory_BreakOutHistory iboh

/*
Create view Fx.dbo.Inventory_ObjectSource
*/

--use Fx
--go

--drop table dbo.Inventory_ObjectSource
if	objectproperty(object_id('dbo.Inventory_ObjectSource'), 'IsView') = 1 begin
	drop view dbo.Inventory_ObjectSource
end
go

create view dbo.Inventory_ObjectSource
as
with
	xBreakOuts
(	ObjectSerial
,	FromSerial
,	ToSerial
,	Level
)
as
(	select
		ObjectSerial = o.serial
	,	FromSerial = iboh.FromSerial
	,	ToSerial = iboh.ToSerial
	,	0
	from
		dbo.object o
		join dbo.Inventory_BreakOutHistory iboh
			on iboh.ToSerial = o.serial
	union all
	select
		ObjectSerial = x.ObjectSerial
	,	FromSerial = iboh.FromSerial
	,	ToSerial = iboh.ToSerial
	,	Level = x.Level + 1
	from
		xBreakouts x
		join dbo.Inventory_BreakOutHistory iboh
			on iboh.ToSerial = x.FromSerial
)
select
	x.ObjectSerial
,	x.FromSerial
,	x.Level
from
	(	select
			x.ObjectSerial
		,	x.FromSerial
		,	x.Level
		,	RowNumber = row_number() over (partition by x.ObjectSerial order by x.Level desc)
		from
			xBreakOuts x
	) x
where
	x.RowNumber = 1
go

select
	*
from
	dbo.Inventory_ObjectSource ios
go

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
			Serial = o.serial
		,	PartCode = o.part
		,	LocationCode = o.location
		,	PlantCode = l.plant
		,	StandardQty = o.std_quantity
		,	StandardUnit = pi.standard_unit
		,	Lot = atCreate.lot
		,	ShipperID = atCreate.shipper
		,	OriginDT = atCreate.date_stamp
		,	OriginType = atCreate.remarks
		,	RowNumber = row_number() over (partition by atCreate.serial order by atCreate.date_stamp)
		from
			dbo.object o
			left join dbo.Inventory_ObjectSource ios
				on ios.ObjectSerial = o.serial
			left join dbo.audit_trail atCreate
				on atCreate.serial = coalesce(ios.FromSerial, o.serial)
			left join dbo.location l
				on o.location = l.code
			join dbo.part_inventory pi
				on pi.part = o.part
	) objectOrigin
where
	RowNumber = 1
order by
	2, 9
go


/*
Create table Fx.dbo.Inventory_QualityInventoryList
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
go

select
	dbo.Inventory_QualityInventoryList.Serial
,	dbo.Inventory_QualityInventoryList.PartCode
,	dbo.Inventory_QualityInventoryList.LocationCode
,	dbo.Inventory_QualityInventoryList.PlantCode
,	dbo.Inventory_QualityInventoryList.StandardQty
,	dbo.Inventory_QualityInventoryList.StandardUnit
,	dbo.Inventory_QualityInventoryList.Lot
,	dbo.Inventory_QualityInventoryList.ShipperID
,	dbo.Inventory_QualityInventoryList.OriginDT
,	dbo.Inventory_QualityInventoryList.OriginType
from
	dbo.Inventory_QualityInventoryList
order by
	2, 9
