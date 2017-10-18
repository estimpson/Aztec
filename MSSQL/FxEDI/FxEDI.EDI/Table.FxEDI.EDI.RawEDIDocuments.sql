
/*
Create Table.FxEDI.EDI.RawEDIDocuments.sql
*/

use FxEDI
go

--drop table EDI.RawEDIDocuments
if	objectproperty(object_id('EDI.RawEDIDocuments'), 'IsTable') is null begin

	create table EDI.RawEDIDocuments
	(	ID int not null identity(1, 1) primary key
	,	GUID uniqueidentifier not null default newid()
	,	Status int not null default (0)
	,	FileName sys.sysname not null
	,	HeaderData xml null
	,	Data xml null
	,	TradingPartnerA varchar (50) null
	,	TypeA varchar (6) null
	,	VersionA varchar (20) null
	,	EDIStandardA varchar (50) null
	,	ReleaseA varchar (50) null
	,	DocNumberA varchar (50) null
	,	ControlNumberA varchar (10) null
	,	DeliveryScheduleA varchar (8) null
	,	MessageNumberA varchar (8) null
	,	RowTS timestamp not null
	,	RowCreateDT datetime null default getdate()
	,	RowCreateUser sys.sysname not null default suser_name()
	)
end
go

create nonclustered index ixRawEDIDocuments_1 on EDI.RawEDIDocuments (Status, EDIStandardA, TypeA)
go
create primary xml index PXML_EDIData on EDI.RawEDIDocuments (Data)
go

select
	*
from
	EDI.RawEDIDocuments
go

