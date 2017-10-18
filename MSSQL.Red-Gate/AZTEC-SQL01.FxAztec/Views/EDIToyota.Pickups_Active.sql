SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [EDIToyota].[Pickups_Active]
AS
SELECT
	ReleaseDate = ss.ReleaseDT
,	PickupDT = ss.ReleaseDT
,	ShipToCode = ss.ShipToCode
--,	PickupCode = ss.SupplierCode
,	PickupCode = COALESCE(ss.UserDefined4, 'NoRouteDefined')
FROM 
	EDIToyota.ShipScheduleHeaders ssh
	JOIN EDIToyota.ShipSchedules ss
		ON ss.RawDocumentGUID = ssh.RawDocumentGUID
		AND ss.Status = 1 --(dbo.udf_StatusValue('EDITOYO.ShipSchedules', 'Active'))
	

WHERE
	ssh.Status = 1 --(dbo.udf_StatusValue('EDITOYO.ShipScheduleHeaders', 'Active'))
	AND ss.ReleaseDT >= DATEADD(DAY, -5, GETDATE())
GROUP BY
	ss.ReleaseDT
,	ss.ShipToCode
--,	ss.SupplierCode
, ss.userDefined4



GO
