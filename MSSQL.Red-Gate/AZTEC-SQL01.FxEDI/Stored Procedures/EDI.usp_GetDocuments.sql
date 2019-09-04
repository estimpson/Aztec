SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [EDI].[usp_GetDocuments]
	@DocType varchar(50)
as
set nocount on
set ansi_warnings on


/* create table variable */
declare @Documents table
(	DocumentGUID uniqueidentifier
,	DocumentQueue int
,	Status int
,	DocumentType varchar(25)
,	DocumentNumber varchar(50)
,	DocumentRevision varchar(25)
,	OriginalDate datetime
,	DocumentArrivalDate datetime
,	ProcessedDate datetime
,	ShipToCode varchar(20)
,	ShipToName varchar(50)
,	BillToCode varchar(10)
,	BillToName varchar(50)
,	EDIOverlayGroup varchar(3)
,	EDIOperatorCode varchar(15)
)


/* populate table variable with appropriate documents */
if @DocType = 'Ford862' begin
	insert @Documents
	(	DocumentGUID
	,	DocumentQueue
	,	Status
	,	DocumentType
	,	DocumentNumber
	,	DocumentRevision
	,	OriginalDate
	,	DocumentArrivalDate
	,	ProcessedDate
	,	ShipToCode
	,	ShipToName
	,	BillToCode
	,	BillToName
	,	EDIOverlayGroup
	,	EDIOperatorCode
	)	
	select
		DocumentGUID = ed.GUID
	,   DocumentQueue = 0
	,	Status =
		case ed.Status
			when 0 then dbo.[udf_StatusValue;1]('EDI.Documents', 'Status', 'RawReceived')
			when 2 then dbo.[udf_StatusValue;1]('EDI.Documents', 'Status', 'RawRequeuded')
			when 0 then dbo.[udf_StatusValue;1]('EDI.Documents', 'Status', 'Staging.1')
		end
	,   DocumentType = 'Ford 862'
	,   DocumentNumber = ed.DocNumber
	,	DocumentRevision = ed.Version
	,	OrginalDate = ed.Data.value('(/TRN-862/SEG-BSS[1]/DE[@code="0373"])[1]', 'datetime')
	,	DocumentArrivalDate = ed.RowCreateDT
	,   ProcessedDate = ed.RowCreateDT
	,	std.ShipToCode
	,	std.ShipToName
	,	std.BillToCode
	,	std.BillToName
	,	std.EDIOverlayGroup
	,	std.EDIOperatorCode
	from
		EDI.EDIDocuments ed
		join EDI.ShipToDimensions std
			on std.ShipToCode = (select ed.Data.value('(/TRN-862/LOOP-N1/SEG-N1 [DE[.="ST"][@code="0098"]]/DE[@code="0067"])[1]', 'varchar(15)'))
	where
		ed.Type = '862'
		and	ed.Version = '002002FORD'
		--and ed.Status in
		--(	0 --dbo.[udf_StatusValue;1]('EDI.EDIDocuments', 'Status', 'New')
		--,	2 --dbo.[udf_StatusValue;1]('EDI.EDIDocuments', 'Status', 'Requeued')
		--,	100 --dbo.[udf_StatusValue;1]('EDI.EDIDocuments', 'Status', 'InProcess')
		--)
end




/* return data */
select * from @Documents


GO
