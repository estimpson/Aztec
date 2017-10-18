
/*
Create View.Fx.EDIToyota.FreightTypes.sql
*/

--use Fx
--go

--drop table EDIToyota.FreightTypes
if	objectproperty(object_id('EDIToyota.FreightTypes'), 'IsView') = 1 begin
	drop view EDIToyota.FreightTypes
end
go

create view EDIToyota.FreightTypes
as
select
	FreightType = Type_name
from
	freight_type_definition
go

select
	ft.FreightType
from
	EDIToyota.FreightTypes ft
order by
	ft.FreightType
go

