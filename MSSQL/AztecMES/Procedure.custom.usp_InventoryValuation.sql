create procedure custom.usp_InventoryValuation
	@InventoryDate datetime
as 

select
	object.PartCode
,	object.StdQty
,	object.UnitMeasure
,	object.StdQty * pi.unit_weight
,	part_standard.cost
,	part_standard.price
,	object.ObjectSerial
,	plant = upper(coalesce(location.plant,'PLANT 1'))
,	part.name
,	part.cross_ref
,	part.class
,	part.type
,	Best1PiecePrice.Price as price1
from
	(	select
			*
		from
			FT.ObjectHistory oh
		where
			oh.RowCreateDT <= @InventoryDate
			and oh.RowID =
			(	select
					max(oh2.RowID)
				from
					FT.ObjectHistory oh2
				where
					oh2.RowCreateDT <= @InventoryDate
					and oh2.ObjectSerial = oh.ObjectSerial
			)
			and oh.Type != -1
	) object
	left outer join location
		on object.LocationCode = location.code
	join part_standard
		on object.PartCode = part_standard.part
	join part
		on object.PartCode = part.part
	join dbo.part_inventory pi
		on pi.part = object.PartCode
	left join REPORT_Best1PiecePrice Best1PiecePrice
		on object.PartCode = Best1PiecePrice.Part
where
	object.LocationCode != 'PRE-OBJECT'
go

