
/*
Create View.Fx.EDIToyota.Carriers.sql
*/

--use Fx
--go

--drop table EDIToyota.Carriers
if	objectproperty(object_id('EDIToyota.Carriers'), 'IsView') = 1 begin
	drop view EDIToyota.Carriers
end
go

create view EDIToyota.Carriers
as
select
	CarrierName = name
,	SCAC = scac
,	DefaultTransMode = trans_mode
from
	carrier
go

select
	c.CarrierName
,   c.SCAC
,   c.DefaultTransMode
from
	EDIToyota.Carriers c
order by
	c.SCAC
go

