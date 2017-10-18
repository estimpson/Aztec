/*	Create recessed seat BOM from non-recessed.*/
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
	parent_part = pRSeat.part
,	part =
		case
				when bomePrototype.part like '1200%' then left(bomePrototype.part, 4) + 'R' + substring(bomePrototype.part, 5, 25)
				else bomePrototype.part
		end
,	start_datetime = getdate()
,	end_datetime = null
,	type = bomePrototype.type
,	quantity = bomePrototype.quantity
,	unit_measure = bomePrototype.unit_measure
,	std_qty = bomePrototype.std_qty
,	scrap_factor = bomePrototype.scrap_factor
,	substitute_part = bomePrototype.substitute_part
,	date_changed = getdate()
from
	dbo.part pRSeat
	join dbo.part pSeat
		on pSeat.part = left(pRSeat.part, patindex ('%R[12][019]%', pRSeat.part) - 1) + substring(pRSeat.part, patindex ('%R[12][019]%', pRSeat.part) + 1, 25)
	join dbo.bill_of_material_ec bomePrototype
		on
		getdate() between bomePrototype.start_datetime and coalesce(bomePrototype.end_datetime, getdate())
		and bomePrototype.parent_part = pSeat.part
	left join dbo.bill_of_material bomPSeat
		on bomPSeat.parent_part = pRSeat.part
		and bomPSeat.part =
			case
				when bomePrototype.part like '1200%' then left(bomePrototype.part, 4) + 'R' + substring(bomePrototype.part, 5, 25)
				else bomePrototype.part
			end
where
	pRSeat.part like '12[136][12347]%[12][019]%'
	and
	(	pRSeat.name like '%RECESSED%'
	or	pRSeat.part like '%1211R[12][019]%'
	or	pRSeat.part like '%LRR[12][019]%'
	or	pRSeat.part like '%RRR[12][019]%'
	or	pRSeat.part like '%SWR[12][019]%'
	)
	and pRSeat.type = 'F'
--	and pRSeat.name like '%RECESSED%'
	and bomPSeat.ID is null
order by
	1, 2

execute
	dbo.usp_Scheduling_BuildXRt 
go

--commit
rollback
go

