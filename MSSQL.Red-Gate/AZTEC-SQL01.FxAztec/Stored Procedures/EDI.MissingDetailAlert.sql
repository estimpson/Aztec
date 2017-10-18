SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [EDI].[MissingDetailAlert]
AS
Begin



SELECT *
INTO 
	#EDIAlertMissingDetail FROM
(

SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version FROM EDIEDIFACT97A.PlanningHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDIEDIFACT97A.PlanningReleases pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT RowID, DocumentImportDT, TradingPartner, DocType,  version FROM EDIEDIFACT96A.PlanningHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDIEDIFACT96A.PlanningReleases pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDI2001.PlanningHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDI2001.PlanningReleases pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDI2002.PlanningHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDI2002.PlanningReleases pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION 
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDI2040.PlanningHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDI2040.PlanningReleases pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDI3010.PlanningHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDI3010.PlanningReleases pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDI3020.PlanningHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDI3020.PlanningReleases pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDI3030.PlanningHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDI3030.PlanningReleases pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDI3060.PlanningHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDI3060.PlanningReleases pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDI4010.PlanningHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDI4010.PlanningReleases pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDIFORD.PlanningHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDIFORD.PlanningReleases pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDIToyota.PlanningHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDIToyota.PlanningReleases pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDIEDIFACT97A.ShipScheduleHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDIEDIFACT97A.ShipSchedules pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDIEDIFACT96A.ShipScheduleHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDIEDIFACT96A.ShipSchedules pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDI2001.ShipScheduleHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDI2001.ShipSchedules pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDI2002.ShipScheduleHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDI2002.ShipSchedules pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION 
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDI2040.ShipScheduleHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDI2040.ShipSchedules pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDI3010.ShipScheduleHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDI3010.ShipSchedules pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDI3020.ShipScheduleHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDI3020.ShipSchedules pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDI3030.ShipScheduleHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDI3030.ShipSchedules pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDI3060.ShipScheduleHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDI3060.ShipSchedules pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDI4010.ShipScheduleHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDI4010.ShipSchedules pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDIFORD.ShipScheduleHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDIFORD.ShipSchedules pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)

UNION
SELECT  RowID, DocumentImportDT, TradingPartner, DocType,  version  FROM EDIToyota.ShipScheduleHeaders ph WHERE NOT EXISTS ( SELECT 1 FROM EDIToyota.ShipSchedules pr WHERE pr.RawDocumentGUID = ph.RawDocumentGUID ) AND ph.RowCreateDT >= dateadd(MINUTE,-10, GETDATE()) AND ph.Status IN (0,1,2)
)
MissingDetail








IF EXISTS (SELECT 1 FROM #EDIAlertMissingDetail)

BEGIN
		

		DECLARE
			@html NVARCHAR(MAX),
			@EmailTableName sysname  = N'#EDIAlertMissingDetail'
		
		exec [FT].[usp_TableToHTML]
				@tableName = @Emailtablename
			,	@orderBy = N'DocumentImportDT'
			,	@html = @html OUTPUT
			,	@includeRowNumber = 0
			,	@camelCaseHeaders = 1
		
		DECLARE
			@EmailBody NVARCHAR(MAX)
		,	@EmailHeader NVARCHAR(MAX) = 'Urgent : Missing Detail For Inbound EDI' 

		SELECT
			@EmailBody =
				N'<H1>' + @EmailHeader + N'</H1>' +
				@html + ' To clear error, set status to -1 on EDI Document Header'

	--print @emailBody

	EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'FxAlerts'-- sysname
	,		@recipients = 'EDIAlert@aztecmfgcorp.com' -- varchar(max)
	,		@copy_recipients = 'rjohnson@aztecmfgcorp.com' -- varchar(max)
	, 	@subject = @EmailHeader
	,  	@body = @EmailBody
	,  	@body_format = 'HTML'
	,		@importance = 'High' 

END

End

GO
