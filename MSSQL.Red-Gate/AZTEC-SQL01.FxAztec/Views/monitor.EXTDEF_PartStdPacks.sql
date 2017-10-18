SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [monitor].[EXTDEF_PartStdPacks]
as
select
	PartID = convert(int, (abs(binary_checksum(p.part)) % (power(2, 5) - 1)) * power(2, 26) + row_number() over (order by p.part))
,	PartCode = p.part
,	Description = p.name
,	GroupTech = p.group_technology
,	StdPack = coalesce (pp.quantity, pi.standard_pack)
,	PackageType = pp.code
from
	dbo.part p
	join dbo.part_inventory pi on
		pi.part = p.part
	left join dbo.part_packaging pp on
		pp.part = p.part
		and
			pp.code = (select max(code) from dbo.part_packaging where part = p.part and quantity = (select max(quantity) from dbo.part_packaging where part = p.part))
where
	p.class not in ('O', 'C')
	and
		p.type not in ('O', 'T')
	and
		p.group_technology > ''
GO
