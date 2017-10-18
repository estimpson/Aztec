SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [EDISUMMIT].[CurrentPlanningReleases]
()
RETURNS @CurrentPlanningReleases TABLE
(	RawDocumentGUID UNIQUEIDENTIFIER
,	ReleaseNo VARCHAR(50)
,	ShipToCode VARCHAR(15)
,	ShipFromCode VARCHAR(15)
,	ConsigneeCode VARCHAR(15)
,	CustomerPart VARCHAR(50)
,	CustomerPO VARCHAR(50)
,	CustomerModelYear VARCHAR(50)
,	NewDocument INT
)
AS
BEGIN
--- <Body>
	INSERT
		@CurrentPlanningReleases
	SELECT DISTINCT
		RawDocumentGUID = ph.RawDocumentGUID
	,	ReleaseNo = COALESCE(pr.ReleaseNo,'')
	,	ShipToCode = pr.ShipToCode
	,	ShipFromCode = COALESCE(pr.ShipFromCode,'')
	,	ConsigneeCode = COALESCE(pr.ConsigneeCode,'')
	,	CustomerPart = pr.CustomerPart
	,	CustomerPO = COALESCE(pr.CustomerPO,'')
	,	CustomerModelYear =  COALESCE(pr.CustomerModelYear,'')
	,	NewDocument =
			CASE
				WHEN ph.Status = 0 --(select dbo.udf_StatusValue('EDISUMMIT.PlanningHeaders', 'Status', 'New'))
					THEN 1
				ELSE 0
			END
	FROM
		(	SELECT
				ShipToCode = pr.ShipToCode
			,	ShipFromCode = ''
			,	ConsigneeCode = ''
			,	CustomerPart = pr.CustomerPart
			,	CustomerPO = ''
			,	CustomerModelYear =  ''
			,	CheckLast = MAX
				(	  CONVERT(CHAR(20), ph.DocumentImportDT, 120)
					+ CONVERT(CHAR(20), ph.DocumentDT, 120)
					
				)
			FROM
				EDISUMMIT.PlanningHeaders ph
				JOIN EDISUMMIT.PlanningReleases pr
					ON pr.RawDocumentGUID = ph.RawDocumentGUID
			WHERE
				ph.Status IN
				(	0 --(select dbo.udf_StatusValue('EDISUMMIT.PlanningHeaders', 'Status', 'New'))
				,	1 --(select dbo.udf_StatusValue('EDISUMMIT.PlanningHeaders', 'Status', 'Active'))
				)
			GROUP BY
				pr.ShipToCode
			,	pr.CustomerPart
		) cl
		JOIN EDISUMMIT.PlanningHeaders ph
			JOIN EDISUMMIT.PlanningReleases pr
				ON pr.RawDocumentGUID = ph.RawDocumentGUID
			ON 
						pr.ShipToCode = cl.ShipToCode
			AND pr.CustomerPart = cl.CustomerPart
			AND	(	CONVERT(CHAR(20), ph.DocumentImportDT, 120) 
						+ CONVERT(CHAR(20), ph.DocumentDT, 120)
					
				) = cl.CheckLast
					LEFT JOIN
			EDISUMMIT.BlanketOrders bo ON bo.EDIShipToCode = pr.ShipToCode
			WHERE ph.RowCreateDT>= DATEADD(dd, COALESCE(bo.PlanningReleaseHorizonDaysBack,-30), GETDATE())
			AND COALESCE(bo.ProcessPlanningRelease,1) = 1
--- </Body>

---	<Return>
	RETURN
END



























GO
