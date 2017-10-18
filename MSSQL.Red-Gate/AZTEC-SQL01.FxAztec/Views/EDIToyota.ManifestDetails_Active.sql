SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [EDIToyota].[ManifestDetails_Active]
AS
SELECT
	ReleaseDate = ss.ReleaseDT
,	PickupDT = ss.ReleaseDT
,	ShipToCode = ss.ShipToCode
--,	PickupCode = ss.SupplierCode
,  PickUpCode = COALESCE(ss.UserDefined4, 'NoRouteDefined')
,	ManifestNumber = ss.UserDefined1
,	CustomerPart = ss.CustomerPart
,	ReturnableContainer = boActive.PackageMaterial
,	Part = boActive.PartCode
,	Quantity = ss.ReleaseQty
,	Racks = COALESCE(ss.ReleaseQty / NULLIF(boActive.StandardPack, 0), -1)
,	OrderNo = boActive.BlanketOrderNo
,	Plant = boActive.Plant
FROM
	EDIToyota.ShipScheduleHeaders ssh
	JOIN EDIToyota.ShipSchedules ss
		ON ss.RawDocumentGUID = ssh.RawDocumentGUID
		AND ss.Status = 1 --(dbo.udf_StatusValue('EDIToyota.ShipSchedules', 'Active'))
	
	JOIN EDIToyota.BlanketOrders boActive
		ON boActive.BlanketOrderNo =
			(	SELECT
					bo.BlanketOrderNo
				FROM
					EDIToyota.BlanketOrders bo
				WHERE
					bo.EDIShipToCode = ss.ShipToCode
					AND bo.CustomerPart = ss.CustomerPart
			)
WHERE
	ssh.Status = 1 --(dbo.udf_StatusValue('EDIToyota.ShipScheduleHeaders', 'Active'))


GO
