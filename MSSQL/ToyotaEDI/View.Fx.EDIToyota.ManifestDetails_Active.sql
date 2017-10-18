/*
Create View.Fx.EDIToyota.ManifestDetails_Active.sql
*/

--use Fx
--go

--drop table EDIToyota.ManifestDetails_Active
if	objectproperty(object_id('EDIToyota.ManifestDetails_Active'), 'IsView') = 1 begin
	drop view EDIToyota.ManifestDetails_Active
end
go

create view EDIToyota.ManifestDetails_Active
as
select
	ReleaseDate = ss.ReleaseDT
,	PickupDT = ss.ReleaseDT
,	ShipToCode = ss.ShipToCode
,	PickupCode = ss.ShipFromCode
,	ManifestNumber = ss.UserDefined1
,	CustomerPart = ss.CustomerPart
,	ReturnableContainer = boActive.PackageMaterial
,	Part = boActive.PartCode
,	Quantity = ss.ReleaseQty
,	Racks = coalesce(ss.ReleaseQty / nullif(boActive.StandardPack, 0), -1)
,	OrderNo = boActive.BlanketOrderNo
,	Plant = boActive.Plant
from
	EDIToyota.ShipScheduleHeaders ssh
	join EDIToyota.ShipSchedules ss
		on ss.RawDocumentGUID = ssh.RawDocumentGUID
		and ss.Status = 1 --(dbo.udf_StatusValue('EDIToyota.ShipSchedules', 'Active'))
	join EDIToyota.BlanketOrders boActive
		on boActive.BlanketOrderNo =
			(	select
					bo.BlanketOrderNo
				from
					EDIToyota.BlanketOrders bo
				where
					bo.EDIShipToCode = ss.ShipToCode
					and bo.CustomerPart = ss.CustomerPart
			)
where
	ssh.Status = 1 --(dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Active'))
go

select
	*
from
	EDIToyota.ManifestDetails_Active mda
