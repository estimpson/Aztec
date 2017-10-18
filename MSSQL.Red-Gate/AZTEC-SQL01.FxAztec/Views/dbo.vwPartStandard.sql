SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[vwPartStandard]
as
select
	Part = p.part
,	Material = coalesce(ps.material, 0)
,	Labor = coalesce(l.standard_rate / pm.parts_per_hour * pm.crew_size, 0)
,	Burden = coalesce(m.standard_rate / pm.parts_per_hour * pm.crew_size, 0)
from
	dbo.part p
	left join dbo.part_machine pm
		on p.part = pm.part
		   and pm.sequence = 1
	left join dbo.machine m
		on pm.machine = m.machine_no
	left join dbo.labor l
		on pm.labor_code = l.id
	left join dbo.part_standard ps
		on p.part = ps.part

GO
