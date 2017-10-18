SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[MES_DefectCodes]
as
select
	DefectCode = dc.code
,	Description = dc.name
,	Department = dc.code_group
,	DepartmentDescription = gt.notes
from
	dbo.defect_codes dc
	left join dbo.group_technology gt
		on gt.id = dc.code_group
GO
