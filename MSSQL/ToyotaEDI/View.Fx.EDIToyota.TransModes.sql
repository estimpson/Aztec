
/*
Create View.Fx.EDIToyota.TransModes.sql
*/

--use Fx
--go

--drop table EDIToyota.TransModes
if	objectproperty(object_id('EDIToyota.TransModes'), 'IsView') = 1 begin
	drop view EDIToyota.TransModes
end
go

create view EDIToyota.TransModes
as
select
	TransModeCode = code
,	TransModeDescription = description
from
	trans_mode
go

select
	tm.TransModeCode
,   tm.TransModeDescription
from
	EDIToyota.TransModes tm
order by
	tm.TransModeCode
go
