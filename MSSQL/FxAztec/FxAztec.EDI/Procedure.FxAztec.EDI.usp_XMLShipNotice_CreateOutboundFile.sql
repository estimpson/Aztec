
/*
Create Procedure.FxAztec.EDI.usp_XMLShipNotice_CreateOutboundFile.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI.usp_XMLShipNotice_CreateOutboundFile'), 'IsProcedure') = 1 begin
	drop procedure EDI.usp_XMLShipNotice_CreateOutboundFile
end
go

create procedure EDI.usp_XMLShipNotice_CreateOutboundFile
	@XMLData xml
,	@ShipperID int
,	@TranDT datetime = null out
,	@Result integer = null out
as
set nocount on
set ansi_warnings on
set	@Result = 999999

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDISupplier.usp_Test
--- </Error Handling>

--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
declare
	@TranCount smallint

set	@TranCount = @@TranCount
if	@TranCount = 0 begin
	begin tran @ProcName
end
else begin
	save tran @ProcName
end
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
declare
	@fileStreamID table
(	FileStreamID uniqueidentifier
)

set ansi_warnings on
		
declare
	@outboundPath sysname =	'\RawEDIData\CustomerEDI\Outbound\Staging'
			
insert
	FxEDI.dbo.RawEDIData
(	file_stream
,	name
,	path_locator
)
output
	inserted.stream_id into @fileStreamID
values
(	convert(varbinary(max), @xmlData)
,	FxEDI.EDI.udf_GetNextRawEDIData_OutboundXML_FileName (@outboundPath)
,	FxEDI.FxFS.udf_GetFilePathLocator(@outboundPath)
)

set ansi_warnings off

insert
	dbo.CustomerEDI_GenerationLog
(	FileStreamID
,	Type
,	ShipperID
,	FileGenerationDT
,	OriginalFileName
,	CurrentFilePath
)
select
	FileStreamID = red.stream_id
,	Type = 1
,	ShipperID = @ShipperID
,	FileGenerationDT = red.last_write_time
,	OriginalFileName = red.name
,	CurrentFilePath = red.file_stream.GetFileNamespacePath()
from
	FxEDI.dbo.RawEDIData red
	join @fileStreamID fsi
		on fsi.FileStreamID = red.stream_id
--- </Body>

---	<CloseTran AutoCommit=Yes>
if	@TranCount = 0 begin
	commit tran @ProcName
end
---	</CloseTran AutoCommit=Yes>

---	<Return>
set	@Result = 0
return
	@Result
--- </Return>
go

