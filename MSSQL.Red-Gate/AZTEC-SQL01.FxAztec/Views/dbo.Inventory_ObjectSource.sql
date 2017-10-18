SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[Inventory_ObjectSource]
as
with
	xBreakOuts
(	ObjectSerial
,	FromSerial
,	ToSerial
,	Level
)
as
(	select
		ObjectSerial = o.serial
	,	FromSerial = iboh.FromSerial
	,	ToSerial = iboh.ToSerial
	,	0
	from
		dbo.object o
		join dbo.Inventory_BreakOutHistory iboh
			on iboh.ToSerial = o.serial
	union all
	select
		ObjectSerial = x.ObjectSerial
	,	FromSerial = iboh.FromSerial
	,	ToSerial = iboh.ToSerial
	,	Level = x.Level + 1
	from
		xBreakouts x
		join dbo.Inventory_BreakOutHistory iboh
			on iboh.ToSerial = x.FromSerial
)
select
	x.ObjectSerial
,	x.FromSerial
,	x.Level
from
	(	select
			x.ObjectSerial
		,	x.FromSerial
		,	x.Level
		,	RowNumber = row_number() over (partition by x.ObjectSerial order by x.Level desc)
		from
			xBreakOuts x
	) x
where
	x.RowNumber = 1
GO
