/*	Create recessed bucket BOMs.*/
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
	parent_part = left(bomePrototype.parent_part, 7) + mcl.ColorCode
,	part = left(bomePrototype.part, 6) + mcl.ColorCode
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
	dbo.part pRBucketBlack
	join custom.MoldingColorLetdown mcl
		on mcl.MoldApplication = 'Bucket'
	join dbo.bill_of_material_ec bomePrototype
		on bomePrototype.parent_part = pRBucketBlack.part
	left join dbo.bill_of_material bomRBucket
		on bomRBucket.parent_part = left(bomePrototype.parent_part, 7) + mcl.ColorCode
		and bomRBucket.part = left(bomePrototype.part, 6) + mcl.ColorCode
where
	pRBucketBlack.part like '1200R%[12][019]B'
	and bomRBucket.ID is null

execute
	dbo.usp_Scheduling_BuildXRt 
go

--commit
rollback
go
