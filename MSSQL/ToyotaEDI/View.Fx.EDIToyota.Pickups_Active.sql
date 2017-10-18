
/*
Create View.Fx.EDIToyota.Pickups_Active.sql
*/

--use Fx
--go

--drop table EDIToyota.Pickups_Active
if	objectproperty(object_id('EDIToyota.Pickups_Active'), 'IsView') = 1 begin
	drop view EDIToyota.Pickups_Active
end
go

create view EDIToyota.Pickups_Active
as
select
	ReleaseDate = ss.ReleaseDT
,	PickupDT = ss.ReleaseDT
,	ShipToCode = ss.ShipToCode
,	PickupCode = ss.ShipFromCode
from
	EDIToyota.ShipScheduleHeaders ssh
	join EDIToyota.ShipSchedules ss
		on ss.RawDocumentGUID = ssh.RawDocumentGUID
		and ss.Status = 1 --(dbo.udf_StatusValue('EDIToyota.ShipSchedules', 'Active'))
where
	ssh.Status = 1 --(dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Active'))
group by
	ss.ReleaseDT
,	ss.ShipToCode
,	ss.ShipFromCode
go
