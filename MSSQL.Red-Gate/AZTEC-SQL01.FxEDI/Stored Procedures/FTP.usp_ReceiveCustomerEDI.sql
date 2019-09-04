SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [FTP].[usp_ReceiveCustomerEDI]
	@ReceiveFileFromFolderRoot sysname = '\RawEDIData\CustomerEDI\Inbound'
,	@TranDT DATETIME = NULL OUT
,	@Result INTEGER = NULL OUT
AS
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
	RETURN
END

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
	set	@CallProcName = 'FS.usp_FileTable_FileMove'
	execute
		@ProcReturn = FS.usp_FileTable_FileMove
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
		GOTO ERROR_HANDLING
	END
	if	@ProcReturn != 0 begin
		set	@Result = 900502
		raiserror ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
		GOTO ERROR_HANDLING
	END
	IF	@ProcResult != 0 BEGIN
		set	@Result = 900502
		raiserror ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
		GOTO ERROR_HANDLING
	END
	--- </Call>
END

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

	REVERT
END

/*	Move inbound files to inprocess folder. */
--- <Call>	
set	@CallProcName = 'FS.usp_FileTable_FileMove'
execute
	@ProcReturn = FS.usp_FileTable_FileMove
	    @FromFolder = @inboundFolder
	,   @ToFolder = @inProcessFolder
	,   @FileNamePattern = '%'
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	GOTO ERROR_HANDLING
END
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	GOTO ERROR_HANDLING
END
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	GOTO ERROR_HANDLING
END
--- </Call>

/*	Copy data from file table into raw XML table.*/
--- <Insert rows="*">
set	@TableName = 'EDI.RawEDIDocuments'

INSERT
	EDI.EDIDocuments
(	GUID
,	FileName
,	HeaderData
,	Data
,	TradingPartner
,	Type
,	Version
,	EDIStandard
,	Release
,	DocNumber
,	ControlNumber
,	DeliverySchedule
,	MessageNumber
,   SourceType
,  MoparSSDDocument
,  VersionEDIFACTorX12
)
SELECT
	GUID = redInboundFiles.stream_id
,	FileName = redInboundFiles.name
,	HeaderData = red.Data.query('/*[1]/TRN-INFO[1]')
,	Data = red.Data
,	TradingPartner = EDI.udf_EDIDocument_TradingPartner(red.Data)
,	Type = EDI.udf_EDIDocument_Type(red.Data)
,	Version = EDI.udf_EDIDocument_Version(red.Data)
,   EDIStandard = CASE 
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
,	Release = EDI.udf_EDIDocument_Release(red.Data)
,	DocNumber = EDI.udf_EDIDocument_DocNumber(red.Data)
,	ControlNumber = EDI.udf_EDIDocument_ControlNumber(red.Data)
,	DeliverySchedule = EDI.udf_EDIDocument_DeliverySchedule(red.Data)
,	MessageNumber = EDI.udf_EDIDocument_MessageNumber(red.Data)
,  SourceType = COALESCE(EDI.udf_EDIDocument_SourceType(red.Data),'')
,  MoparSSDDocument =  COALESCE(EDI.udf_EDIDocument_MoparSSDCRNumberIndicator(red.Data),'')
,  VersionEDIFACTorX12 = CASE WHEN EDI.udf_EDIDocument_Type(Data) LIKE '[A-Z]%' THEN EDI.udf_EDIDocument_Version(red.data)+COALESCE(EDI.udf_EDIDocument_EDIRelease(red.data),EDI.udf_EDIDocument_Version(red.data)) ELSE EDI.udf_EDIDocument_Version(red.data) END
from
	FxEDI.dbo.RawEDIData redInboundFolder
	join FxEDI.dbo.RawEDIData redInboundFiles
		on redInboundFiles.parent_path_locator = redInboundFolder.path_locator
		and redInboundFiles.is_directory = 0
		and redInboundFiles.name like '%'
	cross apply
		(	select
				Data = convert(xml, redInboundFiles.file_stream)
		) red
where
	redInboundFolder.file_stream.GetFileNamespacePath() = @inProcessFolder
	and redInboundFolder.is_directory = 1

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	GOTO ERROR_HANDLING
END
--- </Insert>

/*	Move inbound files to archive folder. */
--- <Call>	
set	@CallProcName = 'FS.usp_FileTable_FileMove'
execute
	--@ProcReturn = 
	FS.usp_FileTable_FileMove
	    @FromFolder = @inProcessFolder
	,   @ToFolder = @archiveFolder
	,   @FileNamePattern = '%'
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	GOTO ERROR_HANDLING
END
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	GOTO ERROR_HANDLING
END
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	GOTO ERROR_HANDLING
END
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
set	@CallProcName = 'FS.usp_FileTable_FileMove'
execute
	@ProcReturn = FS.usp_FileTable_FileMove
		@FromFolder = @inProcessFolder
	,   @ToFolder = @errorFolder
	,   @FileNamePattern = '%'
	,	@TranDT = @TranDT out
	,	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	raiserror ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	RETURN	@Result
END
if	@ProcReturn != 0 begin
	set	@Result = 900502
	raiserror ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	RETURN	@Result
END
if	@ProcResult != 0 begin
	set	@Result = 900502
	raiserror ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	RETURN	@Result
END
--- </Call>
RETURN

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
