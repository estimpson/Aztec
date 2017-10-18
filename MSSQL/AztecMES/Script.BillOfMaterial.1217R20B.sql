begin transaction
go

insert
	dbo.bill_of_material_ec
(	parent_part
,	part
,	start_datetime
,	end_datetime
,	type
,	quantity
,	unit_measure
,	std_qty
,	scrap_factor
,	substitute_part
,	date_changed
)
select
	parent_part = pColoredSeat.part
,	part = coalesce(pColored.part, bomPrototype.part)
,	start_datetime = getdate()
,	end_datetime = null
,	type = bomPrototype.type
,	quantity = bomPrototype.quantity
,	unit_measure = bomPrototype.unit_measure
,	std_qty = bomPrototype.std_qty
,	scrap_factor = bomPrototype.scrap_factor
,	substitute_part = bomPrototype.substitute_part
,	date_changed = getdate()
from
	dbo.bill_of_material_ec bomPrototype
	join part pColoredSeat
		on left (pColoredSeat.part, 7) = '1217R21'
	left join part pColored
		on left(bomPrototype.part, len(bomPrototype.part) - 1) + substring(pColoredSeat.part, 8, 5) = pColored.part
	left join dbo.bill_of_material bomColored
		on bomColored.parent_part = pColoredSeat.part
		and bomColored.part = coalesce(pColored.part, bomPrototype.part)
where
	bomPrototype.parent_part = '1217R21B'
	and bomColored.part is null
	and pColoredSeat.part = '1217R21HGR'
	and getdate() between bomPrototype.start_datetime and coalesce(bomPrototype.end_datetime, getdate())

execute
	dbo.usp_Scheduling_BuildXRt

select
	*
from
	FT.XRt xr
where
	xr.TopPart = '1217R21HGR'
order by
	xr.Sequence

insert
	dbo.bill_of_material_ec
(	parent_part
,	part
,	start_datetime
,	end_datetime
,	type
,	quantity
,	unit_measure
,	std_qty
,	scrap_factor
,	substitute_part
,	date_changed
)
select
	'1200R21HGR'
,   '120021HGR'
,	start_datetime = getdate()
,	end_datetime = null
,	type = bomPrototype.type
,	quantity = bomPrototype.quantity
,	unit_measure = bomPrototype.unit_measure
,	std_qty = bomPrototype.std_qty
,	scrap_factor = bomPrototype.scrap_factor
,	substitute_part = bomPrototype.substitute_part
,	date_changed = getdate()
from
	dbo.bill_of_material_ec bomPrototype
where
	bomPrototype.parent_part = '1200R21B'

go

select
	*
from
	custom.MoldingColorLetdown mcl

--rollback

commit