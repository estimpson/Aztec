
/*
Create View.Fx.dbo.Inventory_ObjectSource.sql
*/

--use Fx
--go

--drop table dbo.Inventory_ObjectSource
if	objectproperty(object_id('dbo.Inventory_ObjectSource'), 'IsView') = 1 begin
	drop view dbo.Inventory_ObjectSource
end
go

create view dbo.Inventory_ObjectSource
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
go

select
	*
from
	dbo.Inventory_ObjectSource ios
go
