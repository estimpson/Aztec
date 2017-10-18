SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [EDI].[EDIdocuments]
as
select
	ei.ID
,   ei.GUID
,   ei.Status
,   ei.FileName
,   ei.Data
,   TradingPartner = EDI.udf_EDIDocument_TradingPartner(ei.Data)
,	Type = EDI.udf_EDIDocument_Type(ei.Data)
,	Version = EDI.udf_EDIDocument_Version(ei.Data)
,	Release = EDI.udf_EDIDocument_Release(ei.Data)
,	DocNumber = EDI.udf_EDIDocument_DocNumber(ei.Data)
,	ControlNumber = EDI.udf_EDIDocument_ControlNumber(ei.Data)
,	DeliverySchedule = EDI.udf_EDIDocument_DeliverySchedule(ei.Data)
,	MessageNumber = EDI.udf_EDIDocument_MessageNumber(ei.Data)
,   ei.RowTS
,   ei.RowCreateDT
,   ei.RowCreateUser
from
	FxEDI.EDI.EDIdocuments ei

GO
