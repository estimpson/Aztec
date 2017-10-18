SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[bill_of_material]
(	parent_part
,	part
,	type
,	quantity
,	unit_measure
,	reference_no
,	std_qty
,	scrap_factor
,	substitute_part
,	ID
,	LastUser
,	LastDT
)
as
select
	bome.parent_part
,	bome.part
,	bome.type
,	bome.quantity
,	bome.unit_measure
,	bome.reference_no
,	bome.std_qty
,	1 / nullif(1 - bome.scrap_factor, 0)
,	bome.substitute_part
,	bome.ID
,	bome.LastUser
,	bome.LastDT
from
	dbo.bill_of_material_ec bome
where
	bome.start_datetime <=getdate() and 
	coalesce (bome.end_datetime, getdate() + 1) > getdate()
GO
