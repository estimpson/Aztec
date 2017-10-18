SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [ChryslerEDI].[fn_ShipperInventory]
(	@ShipperID int
)
returns @ShipperInventory table
(	ShipperID int
,	Part varchar(25)
,	PackageType varchar(25)
,	PalletPackageType varchar(25)
,	PackingSlip varchar(25)
,	QtyPacked numeric(20,6)
,	Boxes int
,	Pallets int
,	NetWeight numeric(20,6)
,	TareWeight numeric(20,6)
,	GrossWeight numeric(20,6)
)
as
begin
--- <Body>
	declare
		@object table
	(	serial int
	,	part varchar(25)
	,	std_quantity numeric(20,6)
	,	weight numeric(20,6)
	,	tare_weight numeric(20,6)
	,	package_type varchar(25)
	,	parent_serial int
	,	shipper int
	)
	
	insert
		@object
	select
		serial = o.serial
	,	part = o.part
	,	std_quantity = o.std_quantity
	,	weight = o.weight
	,	tare_weight = o.tare_weight
	,	package_type = o.package_type
	,	parent_serial = o.parent_serial
	,	shipper = o.shipper
	from
		dbo.object o
	where
		o.shipper = @ShipperID

	declare
		@audit_trail table
	(	serial int
	,	type char(1)
	,	part varchar(25)
	,	std_quantity numeric(20,6)
	,	weight numeric(20,6)
	,	tare_weight numeric(20,6)
	,	package_type varchar(25)
	,	parent_serial int
	,	shipper int
	)
	
	insert
		@audit_trail
	select
		serial = at.serial
	,	type = at.type
	,	part = at.part
	,	std_quantity = at.std_quantity
	,	weight = at.weight
	,	tare_weight = at.tare_weight
	,	package_type = at.package_type
	,	parent_serial = at.parent_serial
	,	shipper = convert(int, at.shipper)
	from
		dbo.audit_trail at
	where
		at.type = 'S'
		and at.shipper = convert(varchar, @ShipperID)
	
	insert
		@ShipperInventory
	select
		ShipperID = convert(varchar, oExp.shipper)
	,	Part = oExp.part
	,	PackageType = min(oExp.package_type)
	,	PalletPackageType = min(oPallet.package_type)
	,	PackingSlip = convert(varchar, oExp.shipper) + 'E' +
			convert
			(	varchar
			,	(	select
					count(distinct oExpC.part)
				from
					@object oExpC
					join dbo.package_materials pmExpC
						on pmExpC.code = oExpC.package_type
						and coalesce(pmExpC.returnable, 'N') != 'Y'
				where
					oExpC.shipper = oExp.Shipper
					and oExpC.part <= oExp.part
				)
			)
	,	QtyPacked = sum(oExp.std_quantity)
	,	Boxes = count(*)
	,	Pallets = count(distinct oExp.parent_serial)
	,	NetWeight = sum(oExp.weight)
	,	TareWeight = sum(oExp.tare_weight)
	,	GrossWeight = sum(oExp.weight + oExp.tare_weight)
	from
		@object oExp
		join dbo.package_materials pmExp
			on pmExp.code = oExp.package_type
			and coalesce(pmExp.returnable, 'N') != 'Y'
		left join @object oPallet
			on oPallet.serial = oExp.parent_serial
	where
		oExp.part != 'PALLET'
		and oExp.shipper > 0
	group by
		oExp.shipper
	,	oExp.part
	union all
	select
		ShipperID = convert(varchar, oRet.shipper)
	,	Part = oRet.Part
	,	PackageType = min(oRet.package_type)
	,	PalletPackageType = min(oPallet.package_type)
	,	PackingSlip = convert(varchar, oRet.shipper) + 'R'/*+
		convert
			(	varchar
			,	(	select
					count(distinct oExpC.part)
				from
					@object oExpC
					join dbo.package_materials pmExpC
						on pmExpC.code = oExpC.package_type
						and coalesce(pmExpC.returnable, 'N') = 'Y'
				where
					oExpC.shipper = oRet.Shipper
					and oExpC.part <= oRet.part
				)
			)*/
	,	QtyPacked = sum(oRet.std_quantity)
	,	Boxes = count(*)
	,	Pallets = count(distinct oRet.parent_serial)
	,	NetWeight = sum(oRet.weight)
	,	TareWeight = sum(oRet.tare_weight)
	,	GrossWeight = sum(oRet.weight + oRet.tare_weight)
	from
		@object oRet
		join dbo.package_materials pmRet
			on pmRet.code = oRet.package_type
			and coalesce(pmRet.returnable, 'N') = 'Y'
		left join @object oPallet
			on oPallet.serial = oRet.parent_serial
	where
		oRet.part != 'PALLET'
		and oRet.shipper > 0
	group by
		oRet.shipper
	,	oRet.Part
	union all
	select
		ShipperID = oExp.shipper
	,	Part = oExp.part
	,	PackageType = min(oExp.package_type)
	,	PalletPackageType = min(oPallet.package_type)
	,	PackingSlip = convert(varchar, oExp.shipper) + 'E' +
			convert
			(	varchar
			,	(	select
					count(distinct oExpC.part)
				from
					@audit_trail oExpC
					join dbo.package_materials pmExpC
						on pmExpC.code = oExpC.package_type
						and coalesce(pmExpC.returnable, 'N') != 'Y'
				where
					oExpC.type = 'S'
					and oExpC.shipper = oExp.Shipper
					and oExpC.part <= oExp.part
				)
			)
	,	QtyPacked = sum(oExp.std_quantity)
	,	Boxes = count(*)
	,	Pallets = count(distinct oExp.parent_serial)
	,	NetWeight = sum(oExp.weight)
	,	TareWeight = sum(oExp.tare_weight)
	,	GrossWeight = sum(oExp.weight + oExp.tare_weight)
	from
		@audit_trail oExp
		join dbo.package_materials pmExp
			on pmExp.code = oExp.package_type
			and coalesce(pmExp.returnable, 'N') != 'Y'
		left join @audit_trail oPallet
			on oPallet.serial = oExp.parent_serial
	where
		oExp.type = 'S'
		and oExp.part != 'PALLET'
		and oExp.shipper > 0
	group by
		oExp.shipper
	,	oExp.part
	union all
	select
		ShipperID = oRet.shipper
	,	Part = oRet.Part
	,	PackageType = min(oRet.package_type)
	,	PalletPackageType = min(oPallet.package_type)
	,	PackingSlip = convert(varchar, oRet.shipper) + 'R'/*+
		convert
			(	varchar
			,	(	select
					count(distinct oExpC.part)
				from
					@audit_trail oExpC
					join dbo.package_materials pmExpC
						on pmExpC.code = oExpC.package_type
						and coalesce(pmExpC.returnable, 'N') = 'Y'
				where
					oExpC.type = 'S'
					and oExpC.shipper = oRet.Shipper
					and oExpC.part <= oRet.part
				)
			)*/
	,	QtyPacked = sum(oRet.std_quantity)
	,	Boxes = count(*)
	,	Pallets = count(distinct oRet.parent_serial)
	,	NetWeight = sum(oRet.weight)
	,	TareWeight = sum(oRet.tare_weight)
	,	GrossWeight = sum(oRet.weight + oRet.tare_weight)
	from
		@audit_trail oRet
		join dbo.package_materials pmRet
			on pmRet.code = oRet.package_type
			and coalesce(pmRet.returnable, 'N') = 'Y'
		left join @audit_trail oPallet
			on oPallet.serial = oRet.parent_serial
	where
		oRet.type = 'S'
		and oRet.part != 'PALLET'
		and oRet.shipper > 0
	group by
		oRet.shipper
	,	oRet.part

	return
end
GO
