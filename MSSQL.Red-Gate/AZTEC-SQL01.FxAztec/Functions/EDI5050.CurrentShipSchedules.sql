SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE FUNCTION [EDI5050].[CurrentShipSchedules]
()
RETURNS @CurrentSS TABLE
(	RawDocumentGUID UNIQUEIDENTIFIER
,	ReleaseNo VARCHAR(50)
,	ShipToCode VARCHAR(50)
,	ShipFromCode VARCHAR(50)
,	ConsigneeCode VARCHAR(50)
,	CustomerPart VARCHAR(50)
,	CustomerPO VARCHAR(50)
,	CustomerModelYear VARCHAR(50)
,	NewDocument INT
)
AS
BEGIN
--- <Body>
	INSERT
		@CurrentSS
	SELECT DISTINCT
		RawDocumentGUID = ssh.RawDocumentGUID
	,	ReleaseNo =  COALESCE(ss.ReleaseNo,'')
	,	ShipToCode = ss.ShipToCode
	,	ShipFromCode = COALESCE(ss.ShipFromCode,'')
	,	ConsigneeCode = COALESCE(ss.ConsigneeCode,'')
	,	CustomerPart = ss.CustomerPart
	,	CustomerPO = COALESCE(ss.CustomerPO,'')
	,	CustomerModelYear = COALESCE(ss.CustomerModelYear,'')
	,	NewDocument =
			CASE
				WHEN ssh.Status = 0 --(select dbo.udf_StatusValue('EDI5050.ShipScheduleHeaders', 'Status', 'New'))
					THEN 1
				ELSE 0
			END
	FROM
		(	SELECT
				ShipToCode = ss.ShipToCode
			,	ShipFromCode = COALESCE(ss.ShipFromCode,'')
			,	ConsigneeCode = ''
			,	CustomerPart = ss.CustomerPart
			,	CustomerPO = ''
			,	CustomerModelYear = COALESCE(ss.CustomerModelYear,'')
			,	CheckLast = MAX
				(	  CONVERT(CHAR(20), ssh.DocumentImportDT, 120)
					+ CONVERT(CHAR(20), ssh.DocumentDT, 120)
 
					
				)
			FROM
				EDI5050.ShipScheduleHeaders ssh
				JOIN EDI5050.ShipSchedules ss
					ON ss.RawDocumentGUID = ssh.RawDocumentGUID
			WHERE
				ssh.Status IN
				(	0 --(select dbo.udf_StatusValue('EDI5050.ShipScheduleHeaders', 'Status', 'New'))
				,	1 --(select dbo.udf_StatusValue('EDI5050.ShipScheduleHeaders', 'Status', 'Active'))
				)
			GROUP BY
				ss.ShipToCode
			,	COALESCE(ss.ShipFromCode,'')
			,	ss.CustomerPart
			,	COALESCE(ss.CustomerModelYear,'')
		) cl
		JOIN EDI5050.ShipScheduleHeaders ssh
			JOIN EDI5050.ShipSchedules ss
			ON ss.RawDocumentGUID = ssh.RawDocumentGUID
			ON ss.ShipToCode = cl.ShipToCode
			AND COALESCE(ss.ShipFromCode, '') = cl.ShipFromCode
			AND ss.CustomerPart = cl.CustomerPart
			AND COALESCE(ss.CustomerModelYear,'') = cl.CustomerModelYear
			AND	(	CONVERT(CHAR(20), ssh.DocumentImportDT, 120)
					+ CONVERT(CHAR(20), ssh.DocumentDT, 120)
 
					
				) = cl.CheckLast
			LEFT JOIN
				EDI5050.BlanketOrders bo ON bo.EDIShipToCode = ss.ShipToCode
			WHERE ss.RowCreateDT>= DATEADD(dd, COALESCE(bo.ShipScheduleHorizonDaysBack,-30), GETDATE())
			AND COALESCE(bo.ProcessShipSchedule,1) = 1
--- </Body>

---	<Return>
	RETURN
END























GO
