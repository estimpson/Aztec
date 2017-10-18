
insert
	dbo.bill_of_material_ec
(	parent_part
,	part
,	start_datetime
,	type
,	quantity
,	unit_measure
,	std_qty
,	scrap_factor
,	substitute_part
,	date_changed
)
select
	parent_part = left(BlackFormulas.MoldedPart, len(BlackFormulas.MoldedPart) - 1) + mcl2.ColorCode
,	part = mcl2.BaseMaterialCode
,	start_datetime = getdate()
,	type = 'M'
,	quantity = BlackFormulas.Resin * (1 - mcl2.LetDownRate)
,	unit_measure = 'EA'
,	std_qty = BlackFormulas.Resin * (1 - mcl2.LetDownRate)
,	scrap_factor = 0
,	substitute_part = 'N'
,	date_changed = getdate()
from
	(	select
			MoldedPart = bom.parent_part
		,	mcl.BaseMaterialCode
		,	Resin = sum(bom2.quantity)
		,	mcl.ColorCode
		from
			custom.MoldingColorLetdown mcl
			join dbo.bill_of_material bom
				on bom.part = mcl.BaseMaterialCode
				and rtrim(bom.parent_part) like '%' + rtrim(convert(varchar, mcl.ColorCode))
				and bom.parent_part not like '%UVB'
			join dbo.bill_of_material bom2
				on bom2.parent_part = bom.parent_part
				and bom2.part in (mcl.BaseMaterialCode, mcl.ColorantCode, 'PL946200002')
		group by
			bom.parent_part
		,	mcl.BaseMaterialCode
		,	mcl.ColorCode
	) BlackFormulas
	join custom.MoldingColorLetdown mcl2
		on left(BlackFormulas.BaseMaterialCode, 8) = left(mcl2.BaseMaterialCode, 8)
		and mcl2.ColorCode != 'B'
	join dbo.part p
		on p.part = left(BlackFormulas.MoldedPart, len(BlackFormulas.MoldedPart) - 1) + mcl2.ColorCode
	left join dbo.bill_of_material bom3
		on bom3.parent_part = p.part
		and bom3.part = mcl2.BaseMaterialCode
where
	BlackFormulas.ColorCode = 'B'
	and	bom3.ID is null
union all
select
	parent_part = left(BlackFormulas.MoldedPart, len(BlackFormulas.MoldedPart) - 1) + mcl2.ColorCode
,	part = mcl2.ColorantCode
,	start_datetime = getdate()
,	type = 'M'
,	quantity = BlackFormulas.Resin * mcl2.LetDownRate
,	unit_measure = 'LB'
,	std_qty = BlackFormulas.Resin * mcl2.LetDownRate
,	scrap_factor = 0
,	substitute_part = 'N'
,	date_changed = getdate()
from
	(	select
			MoldedPart = bom.parent_part
		,	mcl.BaseMaterialCode
		,	Resin = sum(bom2.quantity)
		,	mcl.ColorCode
		from
			custom.MoldingColorLetdown mcl
			join dbo.bill_of_material bom
				on bom.part = mcl.BaseMaterialCode
				and rtrim(bom.parent_part) like '%' + rtrim(convert(varchar, mcl.ColorCode))
				and bom.parent_part not like '%UVB'
			join dbo.bill_of_material bom2
				on bom2.parent_part = bom.parent_part
				and bom2.part in (mcl.BaseMaterialCode, mcl.ColorantCode, 'PL946200002')
		group by
			bom.parent_part
		,	mcl.BaseMaterialCode
		,	mcl.ColorCode
	) BlackFormulas
	join custom.MoldingColorLetdown mcl2
		on left(BlackFormulas.BaseMaterialCode, 8) = left(mcl2.BaseMaterialCode, 8)
		and mcl2.ColorCode != 'B'
	join dbo.part p
		on p.part = left(BlackFormulas.MoldedPart, len(BlackFormulas.MoldedPart) - 1) + mcl2.ColorCode
	left join dbo.bill_of_material bom3
		on bom3.parent_part = p.part
		and bom3.part = mcl2.ColorantCode
where
	BlackFormulas.ColorCode = 'B'
	and	bom3.ID is null
order by
	1, 2


insert
	dbo.part_machine
(	part
,	machine
,	sequence
,	process_id
,	parts_per_hour
,	labor_code
,	activity
,	crew_size
)
select
	p.part
,	BlackMolding.Machine
,	BlackMolding.sequence
,	BlackMolding.Process
,	BlackMolding.PPH
,	BlackMolding.Labor
,	BlackMolding.Activity
,	BlackMolding.CrewSize
from
	(	select
			mcl.BaseMaterialCode
		,	MoldedPart = pm.part
		,	Machine = pm.machine
		,	Sequence = pm.sequence
		,	Process = pm.process_id
		,	PPH = pm.parts_per_cycle
		,	Labor = pm.labor_code
		,	Activity = pm.activity
		,	CrewSize = pm.crew_size
		from
			custom.MoldingColorLetdown mcl
			join dbo.bill_of_material bom
				on bom.part = mcl.BaseMaterialCode
				and rtrim(bom.parent_part) like '%' + rtrim(convert(varchar, mcl.ColorCode))
				and bom.parent_part not like '%UVB'
			join dbo.part_machine pm
				on pm.part = bom.parent_part
	) BlackMolding
	join custom.MoldingColorLetdown mcl2
		on left(BlackMolding.BaseMaterialCode, 8) = left(mcl2.BaseMaterialCode, 8)
		and mcl2.ColorCode != 'B'
	join dbo.part p
		on p.part = left(BlackMolding.MoldedPart, len(BlackMolding.MoldedPart) - 1) + mcl2.ColorCode
	left join dbo.part_machine pm2
		on pm2.part = p.part
where
	pm2.part is null
order by
	1, 2

insert
	dbo.activity_router
(	parent_part
,	sequence
,	code
,	part
,	group_location
)
select
	p.part
,   BlackMolding.Sequence
,   BlackMolding.Activity
,   p.part
,	BlackMolding.Machine
from
	(	select
			mcl.BaseMaterialCode
		,	ParentPart = ar.parent_part
		,   Sequence = ar.sequence
		,   Activity = ar.code
		,   Part = ar.part
		,   Machine = ar.group_location
		from
			custom.MoldingColorLetdown mcl
			join dbo.bill_of_material bom
				on bom.part = mcl.BaseMaterialCode
				and rtrim(bom.parent_part) like '%' + rtrim(convert(varchar, mcl.ColorCode))
				and bom.parent_part not like '%UVB'
			join dbo.activity_router ar
				on ar.part = bom.parent_part
	) BlackMolding
	join custom.MoldingColorLetdown mcl2
		on left(BlackMolding.BaseMaterialCode, 8) = left(mcl2.BaseMaterialCode, 8)
		and mcl2.ColorCode != 'B'
	join dbo.part p
		on p.part = left(BlackMolding.ParentPart, len(BlackMolding.ParentPart) - 1) + mcl2.ColorCode
	left join dbo.activity_router ar2
		on ar2.part = p.part
where
	ar2.part is null

update
	bill_of_material_ec
set
	scrap_factor = coalesce(nullif(scrap_factor, 1), 0)
where
	getdate() between dbo.bill_of_material_ec.start_datetime and coalesce(dbo.bill_of_material_ec.end_datetime, getdate())
