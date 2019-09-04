SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [EDI].[usp_FTP_ReceiveCustomerEDI(obsolete)]
	@ReceiveFileFromFolderRoot sysname = '\RawEDIData\CustomerEDI\Inbound'
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI.usp_Test
--- </Error Handling>

--- <Tran Allowed=No AutoCreate=No TranDTParm=Yes>
if	@@TRANCOUNT > 0 begin

	RAISERROR ('This procedure cannot be run in the context of a transaction.', 16, 1, @ProcName)
	return
end

set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

---	<ArgumentValidation>

---	</ArgumentValidation>

--- <Body>
declare
	@inboundFolder sysname = @receiveFileFromFolderRoot
,	@inProcessFolder sysname = @receiveFileFromFolderRoot + '\InProcess'
,	@archiveFolder sysname = @receiveFileFromFolderRoot + '\Archive'
,	@errorFolder sysname = @receiveFileFromFolderRoot + '\Error'
,	@moveFilePrefix sysname = Replace(convert(varchar(50), getdate(), 126), ':', '') + '.'

declare
	@fhlRow int

insert
	EDI.FTPLogHeaders with (tablockx)
(	Type
,	Description
)
select
	Type = 1
,	Description = 'Receive EDI.'

set	@fhlRow = scope_identity()

if	exists
	(	select
			*
		from
			dbo.RawEDIData redInboundFolder
			join dbo.RawEDIData redInboundFiles
				on redInboundFiles.parent_path_locator = redInboundFolder.path_locator
				and redInboundFiles.is_directory = 0
		where
			redInboundFolder.is_directory = 1
			and redInboundFolder.file_stream.GetFileNamespacePath() = @inProcessFolder
	) begin

	insert
		EDI.FTPLogDetails
	(	FLHRowID
	,	Line
	,	Command
	,	CommandOutput
	)
	select
		FLHRowID = @fhlRow
	,	Line = -1
	,	Command = 'Input Queue not empty.'
	,	CommandOutput = 'Input Queue not empty.'

	/*	Move files to an error folder. */
	--- <Call>
	set	@CallProcName = 'EDI.usp_FileTable_FileMove'
	execute
		@ProcReturn = EDI.usp_FileTable_FileMove
			@FromFolder = @inProcessFolder
		,   @ToFolder = @errorFolder
		,   @FileNamePattern = '%'
		,   @FileAppendPrefix = @moveFilePrefix
		,   @TranDT = @TranDT out
		,	@Result = @ProcResult out

	set	@Error = @@Error
	if	@Error != 0 begin
		set	@Result = 900501
		raiserror ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
		goto ERROR_HANDLING
	end
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		raiserror ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		goto ERROR_HANDLING
	end
	if	@ProcResult != 0 begin
		set	@Result = 900502
		raiserror ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		goto ERROR_HANDLING
	end
	--- </Call>
end

if	not exists
	(	select
			*
		from
			dbo.RawEDIData redInboundFolder
			join dbo.RawEDIData redInboundFiles
				on redInboundFiles.parent_path_locator = redInboundFolder.path_locator
				and redInboundFiles.is_directory = 0
		where
			redInboundFolder.is_directory = 1
			and redInboundFolder.file_stream.GetFileNamespacePath() = @inboundFolder
	) begin

	/*	Use an administrative account. */
	execute as login = 'AZTEC\estimpson'

	declare
		@CommandOutput varchar(max)

	/*	Perform ftp. */
	exec
		FxEDI.EDI.usp_CommandShell_Execute
		@Command = '\\aztec-sql01\fx\FxEDI\RawEDIData\CustomerEDI\FTPCommands\ReceiveInbound_v2.cmd'
	,	@CommandOutput = @CommandOutput out

	insert
		EDI.FTPLogDetails
	(	FLHRowID
	,	Line
	,	Command
	,	CommandOutput
	)
	select
		FLHRowID = @fhlRow
	,	Line = 1
	,	Command = '\\aztec-sql01\fx\FxEDI\RawEDIData\CustomerEDI\FTPCommands\ReceiveInbound_v2.cmd'
	,	CommandOutput = @CommandOutput

	revert
end

/*	Move inbound files to inprocess folder. */
--- <Call>	
set	@CallProcName = 'EDI.usp_FileTable_FileMove'
execute
	@ProcReturn = EDI.usp_FileTable_FileMove
	    @FromFolder = @inboundFolder
	,   @ToFolder = @inProcessFolder
	,   @FileNamePattern = '%'
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	goto ERROR_HANDLING
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	goto ERROR_HANDLING
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	goto ERROR_HANDLING
end
--- </Call>

/*	Copy data from file table into raw XML table.*/
--- <Insert rows="*">
set	@TableName = 'EDI.RawEDIDocuments'

insert
	EDI.RawEDIDocuments
(	GUID
,	FileName
,	Data
)
select
	GUID = redInboundFiles.stream_id
,	FileName = redInboundFiles.name
,	Data = convert(xml, redInboundFiles.file_stream)
from
	FxEDI.dbo.RawEDIData redInboundFolder
	join FxEDI.dbo.RawEDIData redInboundFiles
		on redInboundFiles.parent_path_locator = redInboundFolder.path_locator
		and redInboundFiles.is_directory = 0
		and redInboundFiles.name like '%'
where
	redInboundFolder.file_stream.GetFileNamespacePath() = @inProcessFolder
	and redInboundFolder.is_directory = 1

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	goto ERROR_HANDLING
end
--- </Insert>

/*	Move inbound files to archive folder. */
--- <Call>	
set	@CallProcName = 'EDI.usp_FileTable_FileMove'
execute
	--@ProcReturn = 
	EDI.usp_FileTable_FileMove
	    @FromFolder = @inProcessFolder
	,   @ToFolder = @archiveFolder
	,   @FileNamePattern = '%'
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	goto ERROR_HANDLING
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	goto ERROR_HANDLING
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	goto ERROR_HANDLING
end
--- </Call>
--- </Body>

---	<Return>
set	@Result = 0
return
	@Result
--- </Return>

--	Error handling
ERROR_HANDLING:

/*	Move outbound files to error folder. */
--- <Call>
set	@CallProcName = 'EDI.usp_FileTable_FileMove'
execute
	@ProcReturn = EDI.usp_FileTable_FileMove
		@FromFolder = @inProcessFolder
	,   @ToFolder = @errorFolder
	,   @FileNamePattern = '%'
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	raiserror ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	return	@Result
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	raiserror ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	return	@Result
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	raiserror ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	return	@Result
end
--- </Call>
return

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
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	@ProcReturn = EDI.usp_FTP_ReceiveCustomerEDI
	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

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
