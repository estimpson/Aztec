SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [EDI].[EDIDocuments_bak]
AS



	SELECT
	red.ID
,	red.GUID
,	red.Status
,	red.FileName
,	FullData = red.Data
,	Data = red.HeaderData
,	HeaderData = red.HeaderData
,	TradingPartner = red.TradingPartnerA
,	Type = red.TypeA
,	Version = red.VersionA
,	EDIStandard = red.EDIStandardA
,	Release = red.ReleaseA
,	DocNumber = red.DocNumberA
,	ControlNumber = red.ControlNumberA
,	DeliverySchedule = red.DeliveryScheduleA
,	MessageNumber = red.MessageNumberA
,   SourceType = red.SourceTypeA
,	MoparSSDDocument = red.MoparSSDDocumentA
,	VersionEDIFACTorX12 = red.VersionEDIFACTorX12A
,	red.RowTS
,	red.RowCreateDT
,	red.RowCreateUser
FROM
	EDI.RawEDIDocuments red
	JOIN dbo.RawEDIData reFileTable
		ON reFileTable.stream_id = red.GUID















GO
