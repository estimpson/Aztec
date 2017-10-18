/*	Create bucket BOM from 120019B, 120020B, 120021B*/
select
	LastUser = 'sa'
,	LastDT = getdate()
,	parent_part = pBucket.part
,	part = bomePrototype.part
,	start_datetime = bomePrototype.start_datetime
,	end_datetime = bomePrototype.end_datetime
,	type = bomePrototype.type
,	quantity = bomePrototype.quantity
,	unit_measure = bomePrototype.unit_measure
,	reference_no = bomePrototype.reference_no
,	std_qty = bomePrototype.std_qty
,	scrap_factor = bomePrototype.scrap_factor
,	engineering_level = bomePrototype.engineering_level
,	operator = bomePrototype.operator
,	substitute_part = bomePrototype.substitute_part
,	date_changed = bomePrototype.date_changed
,	note = bomePrototype.note
from
	dbo.bill_of_material_ec bomePrototype
	join dbo.part pBucket
		on pBucket.part like left(bomePrototype.parent_part, 6) + '%'
where
	getdate() between bomePrototype.start_datetime and coalesce(bomePrototype.end_datetime, getdate())
	and bomePrototype.parent_part like '1200[12][901]B'
go

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
	parent_part = pColorBucket.part
,	part = mcl.BaseMaterialCode
,	start_datetime = getdate()
,	end_datetime = null
,	type = 'M'
,	quantity = protoType.pieceWeight * (1 - mcl.LetDownRate)
,	unit_measure = 'EA'
,	std_qty = protoType.pieceWeight * (1 - mcl.LetDownRate)
,	scrap_factor = protoType.baseScrap
,	substitute_part = 'N'
,	date_changed = getdate()
from
	(	select
			Part = bomePrototype.parent_part
		,	pieceWeight = sum(bomePrototype.std_qty)
		,	baseMaterial = max(mclBlackBucket.BaseMaterialCode)
		,	baseScrap = max(case when bomePrototype.part = mclBlackBucket.BaseMaterialCode then bomePrototype.scrap_factor end)
		from
			dbo.bill_of_material_ec bomePrototype
			join custom.MoldingColorLetdown mclBlackBucket
				on bomePrototype.part in (mclBlackBucket.BaseMaterialCode, mclBlackBucket.ColorantCode)
				and mclBlackBucket.ColorCode = 'B'
				and mclBlackBucket.MoldApplication = 'Bucket'
		where
			getdate() between bomePrototype.start_datetime and coalesce(bomePrototype.end_datetime, getdate())
			and bomePrototype.parent_part like '1200[12][901]B'
		group by
			bomePrototype.parent_part
	) protoType
	join custom.MoldingColorLetdown mcl
		on mcl.MoldApplication = 'Bucket'
	join dbo.part pColorBucket
		on pColorBucket.part = left(protoType.Part, 6) + mcl.ColorCode
	left join dbo.bill_of_material bomBase
		on bomBase.parent_part = pColorBucket.part
		and bomBase.part = mcl.BaseMaterialCode
where
	bomBase.ID is null
union all
select
	parent_part = pColorBucket.part
,	part = mcl.ColorantCode
,	start_datetime = getdate()
,	end_datetime = null
,	type = 'M'
,	quantity = protoType.pieceWeight * mcl.LetDownRate
,	unit_measure = 'EA'
,	std_qty = protoType.pieceWeight * mcl.LetDownRate
,	scrap_factor = protoType.colorantScrap
,	substitute_part = 'N'
,	date_changed = getdate()
from
	(	select
			Part = bomePrototype.parent_part
		,	pieceWeight = sum(bomePrototype.std_qty)
		,	baseMaterial = max(mclBlackBucket.BaseMaterialCode)
		,	colorantScrap = max(case when bomePrototype.part = mclBlackBucket.ColorantCode then bomePrototype.scrap_factor end)
		from
			dbo.bill_of_material_ec bomePrototype
			join custom.MoldingColorLetdown mclBlackBucket
				on bomePrototype.part in (mclBlackBucket.BaseMaterialCode, mclBlackBucket.ColorantCode)
				and mclBlackBucket.ColorCode = 'B'
				and mclBlackBucket.MoldApplication = 'Bucket'
		where
			getdate() between bomePrototype.start_datetime and coalesce(bomePrototype.end_datetime, getdate())
			and bomePrototype.parent_part like '1200[12][901]B'
		group by
			bomePrototype.parent_part
	) protoType
	join custom.MoldingColorLetdown mcl
		on mcl.MoldApplication = 'Bucket'
	join dbo.part pColorBucket
		on pColorBucket.part = left(protoType.Part, 6) + mcl.ColorCode
	left join dbo.bill_of_material bomColorant
		on bomColorant.parent_part = pColorBucket.part
		and bomColorant.part = mcl.ColorantCode
where
	bomColorant.ID is null
order by
	1, 2

select
	*
from
	dbo.bill_of_material bom
where
	bom.parent_part like '1200[12][019]%'
order by
	bom.parent_part
,	bom.part

execute
	dbo.usp_Scheduling_BuildXRt 
go

--commit
rollback
go
