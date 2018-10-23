SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [custom].[usp_Label_WipRaw] 
	@Serial int
as
begin

select
	o.serial as Serial
,	p.part as Part
,	p.name as PartName
,	p.cross_ref as Lot
,	convert(varchar(20), convert(int, o.quantity)) as Quantity
,	o.location as Location
,	convert(varchar(10), o.last_date, 101) as LastDate
,	convert(varchar(4), o.last_date, 108) as LastTime
,	o.operator as OperatorCode
,	o.unit_measure as UnitOfMeasure
,	case
		when p.[type] = 'W' then 'WIP'
		else 'RAW'
	end as RawWip
from
	dbo.object o
	join dbo.part p
		on p.part = o.part
where 
	o.serial = @Serial

end
GO
