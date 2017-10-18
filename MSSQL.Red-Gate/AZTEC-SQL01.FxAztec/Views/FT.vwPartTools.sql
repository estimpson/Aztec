SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [FT].[vwPartTools]
as
select distinct
	PartCode = pmt.part
,	ToolCode = 'Tool:' + pmt.tool + coalesce (' | ' + bome.part, '')
from
	dbo.part_machine_tool pmt
	left join dbo.bill_of_material_ec bome on
		pmt.tool = bome.parent_part
GO
