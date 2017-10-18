SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[MES_ObjectComponents]
as

select
	Serial = o.serial
,	Quantity = o.std_quantity
,	UOM = o.unit_measure
,	Component = xrt.ChildPart
from
	FT.XRt xrt
	join object o
		on o.part = xrt.TopPart
where
	BOMLevel = 1


GO
