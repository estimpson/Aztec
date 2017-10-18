
/*
Create table fx21st.fxsys.ObjectHistory
*/

--use fx21st
--go

--drop table FT.ObjectHistory
if	objectproperty(object_id('FT.ObjectHistory'), 'IsTable') is null begin

	create table FT.ObjectHistory
	(	Type int not null
	,	ObjectSerial int
	,	PartCode varchar(25)
	,	LastTranDT datetime
	,	LocationCode varchar(10)
	,	LastOperatorCode varchar(10)
	,	ShortStatus char(1)
	,	LongStatus varchar(30)
	,	StdQty numeric(20,6)
	,	UnitMeasure char(2)
	,	AltQty numeric(20,6)
	,	AltUnitMeasure char(2)
	,	Lot varchar(20)
	,	PackageType varchar(20)
	,	StagedSID int
	,	ParentSerial numeric(10)
	,	Note varchar(254)
	,	StdCost numeric(20,6)
	,	StdMaterial numeric(20,6)
	,	StdLabor numeric(20,6)
	,	StdBurden numeric(20,6)
	,	StdOther numeric(20,6)
	,	PrimaryRowID int references FT.ObjectHistory (RowID)
	,	RowID int identity(1,1) primary key clustered
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	RowModifiedDT datetime default(getdate())
	,	RowModifiedUser sysname default(suser_name())
	)
end
go

--insert
--	FT.ObjectHistory
--(	Type
--,	ObjectSerial
--,	PartCode
--,	LastTranDT
--,	LocationCode
--,	LastOperatorCode
--,	ShortStatus
--,	LongStatus
--,	StdQty
--,	UnitMeasure
--,	AltQty
--,	AltUnitMeasure
--,	Lot
--,	PackageType
--,	StagedSID
--,	ParentSerial
--,	Note
--,	StdCost
--,	StdMaterial
--,	StdLabor
--,	StdBurden
--,	StdOther
--)
--select
--	Type = 1
--,	ObjectSerial = o.serial
--,	PartCode = o.part
--,	LastTranDT = o.last_date
--,	LocationCode = o.location
--,	LastOperatorCode = o.operator
--,	ShortStatus = o.status
--,	LongStatus = o.user_defined_status
--,	StdQty = o.std_quantity
--,	UnitMeasure = pi.standard_unit
--,	AltQty = o.quantity
--,	AltUnitMeasure = nullif(o.unit_measure, pi.standard_unit)
--,	Lot = o.lot
--,	PackageType = o.package_type
--,	StagedSID = o.shipper
--,	ParentSerial = o.parent_serial
--,	Note = o.note
--,	StdCost = ps.cost_cum
--,	StdMaterial = ps.material_cum
--,	StdLabor = ps.labor_cum
--,	StdBurden = ps.burden_cum
--,	StdOther = ps.other_cum
--from
--	dbo.object o
--	left join dbo.part_inventory pi
--		on pi.part = o.part
--	left join dbo.part_standard ps
--		on ps.part = o.part

insert
	FT.ObjectHistory
(	Type
,	ObjectSerial
,	PartCode
,	LastTranDT
,	LocationCode
,	LastOperatorCode
,	ShortStatus
,	LongStatus
,	StdQty
,	UnitMeasure
,	AltQty
,	AltUnitMeasure
,	Lot
,	PackageType
,	StagedSID
,	ParentSerial
,	Note
,	StdCost
,	StdMaterial
,	StdLabor
,	StdBurden
,	StdOther
,	PrimaryRowID
)
select
	Type = -1
,	ObjectHistory.*
from
	(	select
			oh.ObjectSerial
			,   oh.PartCode
			,   oh.LastTranDT
			,   oh.LocationCode
			,   oh.LastOperatorCode
			,   oh.ShortStatus
			,   oh.LongStatus
			,   oh.StdQty
			,   oh.UnitMeasure
			,   oh.AltQty
			,   oh.AltUnitMeasure
			,   oh.Lot
			,   oh.PackageType
			,   oh.StagedSID
			,   oh.ParentSerial
			,   oh.Note
			,   oh.StdCost
			,   oh.StdMaterial
			,   oh.StdLabor
			,   oh.StdBurden
			,   oh.StdOther
			,	PrimaryRowID = oh.RowID
		from
			FT.ObjectHistory oh
		where
			oh.RowID = coalesce
				(	(	select
							max(ohLast.RowID)
						from
							FT.ObjectHistory ohLast
						where
							ohLast.PrimaryRowID = oh.RowID
					)
				,	oh.RowID
				)
			and oh.Type != -1
	) ObjectHistory
	full join 
	(	select
			ObjectSerial = o.serial
		,	PartCode = o.part
		,	LastTranDT = o.last_date
		,	LocationCode = o.location
		,	LastOperatorCode = o.operator
		,	ShortStatus = o.status
		,	LongStatus = o.user_defined_status
		,	StdQty = o.std_quantity
		,	UnitMeasure = pi.standard_unit
		,	AltQty = o.quantity
		,	AltUnitMeasure = nullif(o.unit_measure, pi.standard_unit)
		,	Lot = o.lot
		,	PackageType = o.package_type
		,	StagedSID = o.shipper
		,	ParentSerial = o.parent_serial
		,	Note = o.note
		,	StdCost = ps.cost_cum
		,	StdMaterial = ps.material_cum
		,	StdLabor = ps.labor_cum
		,	StdBurden = ps.burden_cum
		,	StdOther = ps.other_cum
		,	PrimaryRowID = null
		from
			dbo.object o
			left join dbo.part_inventory pi
				on pi.part = o.part
			left join dbo.part_standard ps
				on ps.part = o.part
	) ObjectCurrent
		on ObjectHistory.ObjectSerial = ObjectCurrent.ObjectSerial
where
	ObjectCurrent.ObjectSerial is null

union all

select
	Type = 1
,	ObjectCurrent.*
from
	(	select
			oh.ObjectSerial
			,   oh.PartCode
			,   oh.LastTranDT
			,   oh.LocationCode
			,   oh.LastOperatorCode
			,   oh.ShortStatus
			,   oh.LongStatus
			,   oh.StdQty
			,   oh.UnitMeasure
			,   oh.AltQty
			,   oh.AltUnitMeasure
			,   oh.Lot
			,   oh.PackageType
			,   oh.StagedSID
			,   oh.ParentSerial
			,   oh.Note
			,   oh.StdCost
			,   oh.StdMaterial
			,   oh.StdLabor
			,   oh.StdBurden
			,   oh.StdOther
			,	PrimaryRowID = oh.RowID
		from
			FT.ObjectHistory oh
		where
			oh.RowID = coalesce
				(	(	select
							max(ohLast.RowID)
						from
							FT.ObjectHistory ohLast
						where
							ohLast.PrimaryRowID = oh.RowID
					)
				,	oh.RowID
				)
			and oh.Type != -1
	) ObjectHistory
	full join 
	(	select
			ObjectSerial = o.serial
		,	PartCode = o.part
		,	LastTranDT = o.last_date
		,	LocationCode = o.location
		,	LastOperatorCode = o.operator
		,	ShortStatus = o.status
		,	LongStatus = o.user_defined_status
		,	StdQty = o.std_quantity
		,	UnitMeasure = pi.standard_unit
		,	AltQty = o.quantity
		,	AltUnitMeasure = nullif(o.unit_measure, pi.standard_unit)
		,	Lot = o.lot
		,	PackageType = o.package_type
		,	StagedSID = o.shipper
		,	ParentSerial = o.parent_serial
		,	Note = o.note
		,	StdCost = ps.cost_cum
		,	StdMaterial = ps.material_cum
		,	StdLabor = ps.labor_cum
		,	StdBurden = ps.burden_cum
		,	StdOther = ps.other_cum
		,	PrimaryRowID = null
		from
			dbo.object o
			left join dbo.part_inventory pi
				on pi.part = o.part
			left join dbo.part_standard ps
				on ps.part = o.part
	) ObjectCurrent
		on ObjectHistory.ObjectSerial = ObjectCurrent.ObjectSerial
where
	ObjectHistory.ObjectSerial is null

union all

select
	Type = 0
,	ObjectCurrent.*
from
	(	select
			oh.ObjectSerial
			,   oh.PartCode
			,   oh.LastTranDT
			,   oh.LocationCode
			,   oh.LastOperatorCode
			,   oh.ShortStatus
			,   oh.LongStatus
			,   oh.StdQty
			,   oh.UnitMeasure
			,   oh.AltQty
			,   oh.AltUnitMeasure
			,   oh.Lot
			,   oh.PackageType
			,   oh.StagedSID
			,   oh.ParentSerial
			,   oh.Note
			,   oh.StdCost
			,   oh.StdMaterial
			,   oh.StdLabor
			,   oh.StdBurden
			,   oh.StdOther
			,	PrimaryRowID = oh.RowID
		from
			FT.ObjectHistory oh
		where
			oh.RowID = coalesce
				(	(	select
							max(ohLast.RowID)
						from
							FT.ObjectHistory ohLast
						where
							ohLast.PrimaryRowID = oh.RowID
					)
				,	oh.RowID
				)
			and oh.Type != -1
	) ObjectHistory
	join 
	(	select
			ObjectSerial = o.serial
		,	PartCode = o.part
		,	LastTranDT = o.last_date
		,	LocationCode = o.location
		,	LastOperatorCode = o.operator
		,	ShortStatus = o.status
		,	LongStatus = o.user_defined_status
		,	StdQty = o.std_quantity
		,	UnitMeasure = pi.standard_unit
		,	AltQty = o.quantity
		,	AltUnitMeasure = nullif(o.unit_measure, pi.standard_unit)
		,	Lot = o.lot
		,	PackageType = o.package_type
		,	StagedSID = o.shipper
		,	ParentSerial = o.parent_serial
		,	Note = o.note
		,	StdCost = ps.cost_cum
		,	StdMaterial = ps.material_cum
		,	StdLabor = ps.labor_cum
		,	StdBurden = ps.burden_cum
		,	StdOther = ps.other_cum
		,	PrimaryRowID = null
		from
			dbo.object o
			left join dbo.part_inventory pi
				on pi.part = o.part
			left join dbo.part_standard ps
				on ps.part = o.part
	) ObjectCurrent
		on ObjectHistory.ObjectSerial = ObjectCurrent.ObjectSerial
where
	coalesce(ObjectHistory.PartCode, '~~') != coalesce(ObjectCurrent.PartCode, '~~')
	or coalesce(ObjectHistory.LastTranDT, '1900-01-01') != coalesce(ObjectCurrent.LastTranDT, '1900-01-01')
	or coalesce(ObjectHistory.LocationCode, '~~') != coalesce(ObjectCurrent.LocationCode, '~~')
	or coalesce(ObjectHistory.LastOperatorCode, '~~') != coalesce(ObjectCurrent.LastOperatorCode, '~~')
	or coalesce(ObjectHistory.ShortStatus, '~~') != coalesce(ObjectCurrent.ShortStatus, '~~')
	or coalesce(ObjectHistory.LongStatus, '~~') != coalesce(ObjectCurrent.LongStatus, '~~')
	or coalesce(ObjectHistory.StdQty, -999) != coalesce(ObjectCurrent.StdQty, -999)
	or coalesce(ObjectHistory.UnitMeasure, '~~') != coalesce(ObjectCurrent.UnitMeasure, '~~')
	or coalesce(ObjectHistory.AltQty, -999) != coalesce(ObjectCurrent.AltQty, -999)
	or coalesce(ObjectHistory.AltUnitMeasure, '~~') != coalesce(ObjectCurrent.AltUnitMeasure, '~~')
	or coalesce(ObjectHistory.Lot, '~~') != coalesce(ObjectCurrent.Lot, '~~')
	or coalesce(ObjectHistory.PackageType, '~~') != coalesce(ObjectCurrent.PackageType, '~~')
	or coalesce(ObjectHistory.StagedSID, -999) != coalesce(ObjectCurrent.StagedSID, -999)
	or coalesce(ObjectHistory.ParentSerial, -999) != coalesce(ObjectCurrent.ParentSerial, -999)
	or coalesce(ObjectHistory.Note, '~~') != coalesce(ObjectCurrent.Note, '~~')
	or coalesce(ObjectHistory.StdCost, -999) != coalesce(ObjectCurrent.StdCost, -999)
	or coalesce(ObjectHistory.StdMaterial, -999) != coalesce(ObjectCurrent.StdMaterial, -999)
	or coalesce(ObjectHistory.StdLabor, -999) != coalesce(ObjectCurrent.StdLabor, -999)
	or coalesce(ObjectHistory.StdBurden, -999) != coalesce(ObjectCurrent.StdBurden, -999)
	or coalesce(ObjectHistory.StdOther, -999) != coalesce(ObjectCurrent.StdOther, -999)
go


alter trigger trObjectHistory on dbo.object after insert, update, delete
as
declare
	@ObjectHistory table
(	ObjectSerial int
,	PartCode varchar(25)
,	LastTranDT datetime
,	LocationCode varchar(10)
,	LastOperatorCode varchar(10)
,	ShortStatus char(1)
,	LongStatus varchar(30)
,	StdQty numeric(20,6)
,	UnitMeasure char(2)
,	AltQty numeric(20,6)
,	AltUnitMeasure char(2)
,	Lot varchar(20)
,	PackageType varchar(20)
,	StagedSID int
,	ParentSerial numeric(10)
,	Note varchar(254)
,	StdCost numeric(20,6)
,	StdMaterial numeric(20,6)
,	StdLabor numeric(20,6)
,	StdBurden numeric(20,6)
,	StdOther numeric(20,6)
,	PrimaryRowID int
)

insert
	@ObjectHistory
select
	oh.ObjectSerial
	,   oh.PartCode
	,   oh.LastTranDT
	,   oh.LocationCode
	,   oh.LastOperatorCode
	,   oh.ShortStatus
	,   oh.LongStatus
	,   oh.StdQty
	,   oh.UnitMeasure
	,   oh.AltQty
	,   oh.AltUnitMeasure
	,   oh.Lot
	,   oh.PackageType
	,   oh.StagedSID
	,   oh.ParentSerial
	,   oh.Note
	,   oh.StdCost
	,   oh.StdMaterial
	,   oh.StdLabor
	,   oh.StdBurden
	,   oh.StdOther
	,	PrimaryRowID = coalesce(oh.PrimaryRowID, oh.RowID)
from
	FT.ObjectHistory oh
	join deleted d
		full join inserted i
			on i.serial = d.serial
		on coalesce(d.serial, i.serial) = oh.ObjectSerial
where
	oh.RowID = coalesce
		(	(	select
					max(ohLast.RowID)
				from
					FT.ObjectHistory ohLast
				where
					ohLast.PrimaryRowID = oh.RowID
			)
		,	oh.RowID
		)
	and oh.Type != -1

insert
	FT.ObjectHistory
(	Type
,	ObjectSerial
,	PartCode
,	LastTranDT
,	LocationCode
,	LastOperatorCode
,	ShortStatus
,	LongStatus
,	StdQty
,	UnitMeasure
,	AltQty
,	AltUnitMeasure
,	Lot
,	PackageType
,	StagedSID
,	ParentSerial
,	Note
,	StdCost
,	StdMaterial
,	StdLabor
,	StdBurden
,	StdOther
,	PrimaryRowID
)
select
	Type = -1
,	ObjectDeleted.*
,	PrimaryRowID = ObjectHistory.PrimaryRowID
from
	@ObjectHistory ObjectHistory
	join 
	(	select
			ObjectSerial = o.serial
		,	PartCode = o.part
		,	LastTranDT = o.last_date
		,	LocationCode = o.location
		,	LastOperatorCode = o.operator
		,	ShortStatus = o.status
		,	LongStatus = o.user_defined_status
		,	StdQty = o.std_quantity
		,	UnitMeasure = pi.standard_unit
		,	AltQty = o.quantity
		,	AltUnitMeasure = nullif(o.unit_measure, pi.standard_unit)
		,	Lot = o.lot
		,	PackageType = o.package_type
		,	StagedSID = o.shipper
		,	ParentSerial = o.parent_serial
		,	Note = o.note
		,	StdCost = ps.cost_cum
		,	StdMaterial = ps.material_cum
		,	StdLabor = ps.labor_cum
		,	StdBurden = ps.burden_cum
		,	StdOther = ps.other_cum
		from
			deleted o
			left join inserted i
				on i.serial = o.serial
			left join dbo.part_inventory pi
				on pi.part = o.part
			left join dbo.part_standard ps
				on ps.part = o.part
		where
			i.serial is null
	) ObjectDeleted
		on ObjectDeleted.ObjectSerial = ObjectHistory.ObjectSerial

union all

select
	Type = 1
,	ObjectInserted.*
,	PrimaryRowID = null
from
	(	select
			ObjectSerial = o.serial
		,	PartCode = o.part
		,	LastTranDT = o.last_date
		,	LocationCode = o.location
		,	LastOperatorCode = o.operator
		,	ShortStatus = o.status
		,	LongStatus = o.user_defined_status
		,	StdQty = o.std_quantity
		,	UnitMeasure = pi.standard_unit
		,	AltQty = o.quantity
		,	AltUnitMeasure = nullif(o.unit_measure, pi.standard_unit)
		,	Lot = o.lot
		,	PackageType = o.package_type
		,	StagedSID = o.shipper
		,	ParentSerial = o.parent_serial
		,	Note = o.note
		,	StdCost = ps.cost_cum
		,	StdMaterial = ps.material_cum
		,	StdLabor = ps.labor_cum
		,	StdBurden = ps.burden_cum
		,	StdOther = ps.other_cum
		from
			inserted o
			left join deleted d
				on d.serial = o.serial
			left join dbo.part_inventory pi
				on pi.part = o.part
			left join dbo.part_standard ps
				on ps.part = o.part
		where
			d.serial is null
	) ObjectInserted

union all

select
	Type = 0
,	ObjectUpdated.*
,	PrimaryRowID = ObjectHistory.PrimaryRowID
from
	@ObjectHistory ObjectHistory
	join 
	(	select
			ObjectSerial = o.serial
		,	PartCode = o.part
		,	LastTranDT = o.last_date
		,	LocationCode = o.location
		,	LastOperatorCode = o.operator
		,	ShortStatus = o.status
		,	LongStatus = o.user_defined_status
		,	StdQty = o.std_quantity
		,	UnitMeasure = pi.standard_unit
		,	AltQty = o.quantity
		,	AltUnitMeasure = nullif(o.unit_measure, pi.standard_unit)
		,	Lot = o.lot
		,	PackageType = o.package_type
		,	StagedSID = o.shipper
		,	ParentSerial = o.parent_serial
		,	Note = o.note
		,	StdCost = ps.cost_cum
		,	StdMaterial = ps.material_cum
		,	StdLabor = ps.labor_cum
		,	StdBurden = ps.burden_cum
		,	StdOther = ps.other_cum
		from
			inserted o
			join deleted d
				on d.serial = o.serial
			left join dbo.part_inventory pi
				on pi.part = o.part
			left join dbo.part_standard ps
				on ps.part = o.part
	) ObjectUpdated
		on ObjectUpdated.ObjectSerial = ObjectHistory.ObjectSerial
go
