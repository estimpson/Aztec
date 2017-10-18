
/*
Create Procedure.FxEDI.FS.usp_FileTable_FileMove.sql
*/

use FxEDI
go

if	objectproperty(object_id('FS.usp_FileTable_FileMove'), 'IsProcedure') = 1 begin
	drop procedure FS.usp_FileTable_FileMove
end
go

create procedure FS.usp_FileTable_FileMove
	@FromFolder sysname = '%'
,	@ToFolder sysname
,	@FileNamePattern sysname
,	@FileAppendPrefix sysname = null
,	@FileAppendSuffix sysname = null
,	@TranDT datetime = null out
,	@Result integer = null out
as
set nocount on
set ansi_warnings off
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. FS.usp_Test
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
	@newpath hierarchyid

select
	@newpath = path_locator
from
	FxEDI.dbo.RawEDIData re
where
	file_stream.GetFileNamespacePath() = @ToFolder

if	@newpath is null begin
	set	@Result = 999998
	RAISERROR ('Error encountered in %s.  Failure: Invalid "ToFolder" specified.  Folder "%s" not found.', 16, 1, @ProcName, @ToFolder)
	rollback tran @ProcName
	return	@Result
end

set ansi_warnings on

update
	redOutboundFiles
set
	path_locator = redOutboundFiles.path_locator.GetReparentedValue(redOutboundFolder.path_locator, @newpath)
,	name = coalesce(@FileAppendPrefix, '') + redOutboundFiles.name + coalesce(@FileAppendSuffix, '')
from
	FxEDI.dbo.RawEDIData redOutboundFolder
	join FxEDI.dbo.RawEDIData redOutboundFiles
		on redOutboundFiles.parent_path_locator = redOutboundFolder.path_locator
		and redOutboundFiles.is_directory = 0
		and redOutboundFiles.name like @FileNamePattern
where
	redOutboundFolder.file_stream.GetFileNamespacePath() like @FromFolder
	and redOutboundFolder.is_directory = 1
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

/*
Example:
Initial queries
{

}

Test syntax
{

set statistics io on
set statistics time on
go

declare
	@FromFolder sysname = '%'
,	@ToFolder sysname
,	@FileNamePattern sysname
,	@FileAppendPrefix sysname = null
,	@FileAppendSuffix sysname = null

set	@FromFolder = '\RawEDIData\Outbound\InProcess'
set @ToFolder = '\RawEDIData\Outbound\Sent'
set @FileNamePattern = '2014-02-17T093521.740.outbound00001.xml'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = FS.usp_FileTable_FileMove
	@FromFolder = @FromFolder
,	@ToFolder = @ToFolder
,	@FileNamePattern = @FileNamePattern
,	@FileAppendPrefix = @FileAppendPrefix
,	@FileAppendSuffix = @FileAppendSuffix
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult

select
	red.file_stream.GetFileNamespacePath()
,   *
from
	dbo.RawEDIData red
where
	red.name like @FileNamePattern
go

--commit
if	@@trancount > 0 begin
	rollback
end
go

set statistics io off
set statistics time off
go

}

Results {
}
*/
GO
