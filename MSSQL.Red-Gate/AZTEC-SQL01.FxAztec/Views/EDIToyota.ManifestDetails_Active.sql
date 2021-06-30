SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [EDIToyota].[ManifestDetails_Active]
as
select
	ReleaseDate = ss.ReleaseDT
,	PickupDT = ss.ReleaseDT
,	ShipToCode = ss.ShipToCode
--,	PickupCode = ss.SupplierCode
,	PickUpCode = coalesce(ss.UserDefined4, 'NoRouteDefined')
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
		(
			select
				bo	.BlanketOrderNo
			from
				EDIToyota.BlanketOrders bo
			where
				bo.EDIShipToCode = ss.ShipToCode
				and bo.CustomerPart = ss.CustomerPart
		)
where
	ssh.Status = 1	--(dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Active'))
	and ss.UserDefined1 > ''
GO
