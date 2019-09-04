SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [EDI].[usp_LoadInboundEDI;Obsolete]
AS
/*	Move all files that are in the Inbound folder to the Inbound\InProcess folder. */
DECLARE
	@oldpath HIERARCHYID
,	@newpath HIERARCHYID

SELECT TOP 1
	@oldpath = red.path_locator
FROM
	dbo.RawEDIData red
WHERE
--	file_stream.GetFileNamespacePath() = '\RawEDIData\Inbound'
	red.name = 'Inbound'
	AND red.parent_path_locator IS NULL

SELECT
	@newpath = red.path_locator
FROM
	dbo.RawEDIData red
WHERE
--	file_stream.GetFileNamespacePath() = '\RawEDIData\Inbound\InProcess'
	red.name = 'InProcess'
	AND red.parent_path_locator =
		(	SELECT
				red.path_locator
			FROM
				dbo.RawEDIData red
			WHERE
				red.name = 'Inbound'
				AND red.parent_path_locator IS NULL
		)

UPDATE
	re
SET
	path_locator = path_locator.GetReparentedValue(@oldpath, @newpath)
,	name = REPLACE(CONVERT(VARCHAR(50), GETDATE(), 126), ':', '') + '.' + re.name
FROM
	dbo.RawEDIData re
WHERE
	--re.file_stream.GetFileNamespacePath() like '\RawEDIData\Inbound\%'
	--and re.path_locator.GetLevel() = 2
	--and is_directory = 0
	re.parent_path_locator = @oldpath
	AND is_directory = 0

INSERT
	EDI.RawEDIDocuments
(	GUID
,	FileName
,	HeaderData
,	Data
,	TradingPartnerA
,	TypeA
,	VersionA
,	EDIStandardA
,	ReleaseA
,	DocNumberA
,	ControlNumberA
,	DeliveryScheduleA
,	MessageNumberA
,   SourceTypeA
,  MoparSSDDocumentA
,  VersionEDIFACTorX12A
)
SELECT
	GUID = re.stream_id
,	FileName = re.name
,	HeaderData = red.Data.query('/*[1]/TRN-INFO[1]')
,	Data = red.Data
,	TradingPartnerA = EDI.udf_EDIDocument_TradingPartner(red.Data)
,	TypeA = EDI.udf_EDIDocument_Type(red.Data)
,	VersionA = EDI.udf_EDIDocument_Version(red.Data)
,   EDIStandardA = CASE 
			WHEN EDI.udf_EDIDocument_TradingPartner(red.Data) LIKE '%Chrysler%' AND EDI.udf_EDIDocument_MoparSSDCRNumberIndicator(red.Data) != 1
			THEN '00CHRY'
			WHEN EDI.udf_EDIDocument_TradingPartner(red.Data) LIKE '%Ford%' 
			THEN '00FORD'
			WHEN EDI.udf_EDIDocument_TradingPartner(red.Data) LIKE '%Toyota%' 
			THEN '00TOYO'
			WHEN EDI.udf_EDIDocument_TradingPartner(red.Data) LIKE '%Dana Corporation%' 
			THEN CASE WHEN EDI.udf_EDIDocument_Type(red.Data) LIKE '[A-Z]%' THEN EDI.udf_EDIDocument_Version(red.data)+COALESCE(EDI.udf_EDIDocument_EDIRelease(red.data),EDI.udf_EDIDocument_Version(red.data)) ELSE EDI.udf_EDIDocument_Version(red.data) END
			WHEN EDI.udf_EDIDocument_TradingPartner(red.Data) LIKE '%TRW%' 
			THEN CASE WHEN EDI.udf_EDIDocument_Type(red.Data) LIKE '[A-Z]%' THEN EDI.udf_EDIDocument_Version(red.data)+COALESCE(EDI.udf_EDIDocument_EDIRelease(red.data),EDI.udf_EDIDocument_Version(red.data)) ELSE EDI.udf_EDIDocument_Version(red.data) END
			WHEN EDI.udf_EDIDocument_TradingPartner(red.Data) LIKE '%Mazda Corporation%' 
			THEN '002001'
			WHEN  EDI.udf_EDIDocument_MoparSSDCRNumberIndicator(red.Data) = 1
			THEN 'MOPARSSD'
			ELSE 
			(CASE WHEN EDI.udf_EDIDocument_Type(Data) LIKE '[A-Z]%' THEN EDI.udf_EDIDocument_Version(red.data)+COALESCE(EDI.udf_EDIDocument_EDIRelease(red.data),EDI.udf_EDIDocument_Version(red.data)) ELSE EDI.udf_EDIDocument_Version(red.data) END)
			END
,	ReleaseA = EDI.udf_EDIDocument_Release(red.Data)
,	DocNumberA = EDI.udf_EDIDocument_DocNumber(red.Data)
,	ControlNumberA = EDI.udf_EDIDocument_ControlNumber(red.Data)
,	DeliveryScheduleA = EDI.udf_EDIDocument_DeliverySchedule(red.Data)
,	MessageNumberA = EDI.udf_EDIDocument_MessageNumber(red.Data)
,  SourceTypeA = COALESCE(EDI.udf_EDIDocument_SourceType(red.Data),'')
,  MoparSSDDocumentA =  COALESCE(EDI.udf_EDIDocument_MoparSSDCRNumberIndicator(red.Data),'')
,  VersionEDIFACTorX12A = CASE WHEN EDI.udf_EDIDocument_Type(Data) LIKE '[A-Z]%' THEN EDI.udf_EDIDocument_Version(red.data)+COALESCE(EDI.udf_EDIDocument_EDIRelease(red.data),EDI.udf_EDIDocument_Version(red.data)) ELSE EDI.udf_EDIDocument_Version(red.data) END
FROM
	dbo.RawEDIData re
	CROSS APPLY (SELECT Data = CONVERT(XML, re.file_stream)) red
WHERE
	--re.file_stream.GetFileNamespacePath() like '\RawEDIData\Inbound\InProcess%'
	--and re.path_locator.GetLevel() = 3
	--and is_directory = 0
	re.parent_path_locator = @newpath
	AND is_directory = 0

SET	@oldpath = @newpath --'\RawEDIData\Inbound\InProcess'
--select
	--@oldpath = path_locator
--from
--	dbo.RawEDIData re
--where
	--file_stream.GetFileNamespacePath() = '\RawEDIData\Inbound\InProcess'

SELECT
	@newpath = red.path_locator
FROM
	dbo.RawEDIData red
WHERE
	--file_stream.GetFileNamespacePath() = '\RawEDIData\Archive'
	red.name = 'Archive'
	AND red.parent_path_locator IS NULL

UPDATE
	re
SET
	path_locator = path_locator.GetReparentedValue(@oldpath, @newpath)
FROM
	dbo.RawEDIData re
WHERE
	--re.file_stream.GetFileNamespacePath() like '\RawEDIData\Inbound\InProcess\%'
	--and re.path_locator.GetLevel() = 3
	--and is_directory = 0
	re.parent_path_locator = @oldpath
	AND is_directory = 0






GO
