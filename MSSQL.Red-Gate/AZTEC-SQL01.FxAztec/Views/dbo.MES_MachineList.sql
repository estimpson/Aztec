SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[MES_MachineList]
as
select
	GroupTechnology = gt.id
,	MachineCode = m.machine_no
,   Description = m.mach_descp
,	Plant = l.plant
from
	dbo.machine m
	join dbo.location l
		on l.code = m.machine_no
	left join dbo.group_technology gt
		on gt.id = l.group_no
GO
