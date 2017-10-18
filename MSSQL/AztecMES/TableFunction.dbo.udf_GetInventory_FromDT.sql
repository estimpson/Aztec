
if	objectproperty(object_id('dbo.udf_GetInventory_FromDT'), 'IsTableFunction') = 1 begin
	drop function dbo.udf_GetInventory_FromDT
end
go

create function dbo.udf_GetInventory_FromDT
(	@InventoryDT datetime
)
returns @Objects table
(	ObjectSerial int null
,	PartCode varchar (25) null
,	LastTranDT datetime null
,	LocationCode varchar (10) null
,	LastOperatorCode varchar (10) null
,	ShortStatus char (1) null
,	LongStatus varchar (30) null
,	StdQty numeric (20, 6) null
,	UnitMeasure char (2) null
,	AltQty numeric (20, 6) null
,	AltUnitMeasure char (2) null
,	Lot varchar (20) null
,	PackageType varchar (20) null
,	StagedSID int null
,	ParentSerial numeric (10, 0) null
,	Note varchar (254) null
,	StdCost numeric (20, 6) null
,	StdMaterial numeric (20, 6) null
,	StdLabor numeric (20, 6) null
,	StdBurden numeric (20, 6) null
,	StdOther numeric (20, 6) null
)
as
begin
--- <Body>
	insert
		@Objects
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
	from
		FT.ObjectHistory oh
	where
		oh.RowCreateDT <= @InventoryDT
		and oh.RowID =
		(	select
				max(oh2.RowID)
			from
				FT.ObjectHistory oh2
			where
				oh2.RowCreateDT <= @InventoryDT
				and oh2.ObjectSerial = oh.ObjectSerial
		)
		and oh.Type != -1
--- </Body>

---	<Return>
	return
end
go

select
	*
from
	dbo.udf_GetInventory_FromDT ('2011-12-01')

declare
	@InventoryDT datetime

set	@InventoryDT = '2011-12-02'

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
from
	FT.ObjectHistory oh
where
	oh.RowCreateDT <= @InventoryDT
	and oh.RowID =
	(	select
			max(oh2.RowID)
		from
			FT.ObjectHistory oh2
		where
			oh2.RowCreateDT <= @InventoryDT
			and oh2.ObjectSerial = oh.ObjectSerial
	)
	and oh.Type != -1