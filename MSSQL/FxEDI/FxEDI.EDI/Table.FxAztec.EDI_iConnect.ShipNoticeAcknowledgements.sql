
/*
Create Table.FxEDI.EDI.EDIDocuments.sql
*/

--use FxEDI
--go

drop table EDI.EDIDocuments
if	objectproperty(object_id('EDI.EDIDocuments'), 'IsTable') is null begin

	create table EDI.EDIDocuments
	(	ID int not null IDENTITY(1, 1) primary key
	,	GUID uniqueidentifier not null default(newid())
	,	Status int not null default(0)
	,	FileName sysname not null
	,	HeaderData xml null
	,	RowTS timestamp
	,	RowCreateDT datetime default(getdate())
	,	RowCreateUser sysname default(suser_name())
	,	Data xml null
	,	TradingPartner varchar(50) null
	,	Type varchar(6) null
	,	Version varchar(20) null
	,	EDIStandard varchar(50) null
	,	Release varchar(50) null
	,	DocNumber varchar(50) null
	,	ControlNumber varchar(10) null
	,	DeliverySchedule varchar(8) null
	,	MessageNumber varchar(8) null
	,	SourceType varchar(50) null
	,	MoparSSDDocument varchar(50) null
	,	VersionEDIFACTorX12 varchar(50) null
	,	unique nonclustered
		(	uniqueColumn
		)
	)
end
go

create nonclustered index ixRawEDIDocuments_1 on EDI.EDIDocuments (Status, EDIStandard, Type)
go
create primary xml index PXML_EDIData on EDI.EDIDocuments (Data)
go

