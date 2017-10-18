SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create view [EDI].[vwEDIDocuments]
as
select
	ID
,	GUID
,	Status
,	FileName
,	Data
,	TradingPartner = EDI.udf_EDIDocument_TradingPartner(Data)
,	Type = EDI.udf_EDIDocument_Type(Data)
,	Version = EDI.udf_EDIDocument_Version(Data)
,	Release = EDI.udf_EDIDocument_Release(Data)
,	DocNumber = EDI.udf_EDIDocument_DocNumber(Data)
,	DocNumber2 = EDI.udf_EDIDocument_DocNumber2(Data)
,	ControlNumber = EDI.udf_EDIDocument_ControlNumber(Data)
,	DeliverySchedule = EDI.udf_EDIDocument_DeliverySchedule(Data)
,	MessageNumber = EDI.udf_EDIDocument_MessageNumber(Data)
,	RowTS
,	RowCreateDT
,	RowCreateUser
from
	EDI.EDIDocuments red



GO
