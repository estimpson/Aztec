SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[usp_Notification_SendEmail]
	@EmailTo nvarchar(4000)
,	@EmailCC nvarchar(4000)
,	@EmailReplyTo nvarchar(4000)
,	@EmailSubject nvarchar(4000)
,	@EmailBody nvarchar(4000)
,	@EmailAttachmentNames nvarchar(4000)
,	@EmailFrom nvarchar(4000)
,	@MailItemID int = null out
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
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
--- <Call>	
set	@CallProcName = '[callProc]'
execute
	@ProcReturn = msdb.dbo.sp_send_dbmail
	@recipients = @EmailTo
,	@copy_recipients = @EmailCC
--,	@blind_copy_recipients = 'estimpson@fore-thought.com;aboulanger@fore-thought.com'
,	@subject = @EmailSubject
,	@body = @EmailBody
,	@file_attachments = @EmailAttachmentNames
,	@reply_to = @EmailReplyTo
,	@from_address = @EmailFrom
,	@mailitem_id = @MailItemID out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran @ProcName
	return	@Result
end
--- </Call>

--- </Body>

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
	@EmailTo nvarchar(4000)
,	@EmailCC nvarchar(4000)
,	@EmailReplyTo nvarchar(4000)
,	@EmailSubject nvarchar(4000)
,	@EmailBody nvarchar(4000)
,	@EmailAttachmentNames nvarchar(4000)
,	@EmailFrom nvarchar(4000)

set	@EmailTo = 'rjohnson@aztecmfgcorp.com'
set	@EmailCC = 'mkroll@aztecmfgcorp.com'
set	@EmailReplyTo = 'rvasqez@aztecmfgcorp.com'
set	@EmailSubject = 'SendEmail'
set	@EmailBody = 'test fxAztecTest.dbo.usp_Notification_SendEmail'
set	@EmailAttachmentNames = null
set	@EmailFrom = 'NoReply@aztecmfgcorp.com.com'

--begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	dbo.usp_Notification_SendEmail
	@EmailTo = @EmailTo
,	@EmailCC = @EmailCC
,	@EmailReplyTo = @EmailReplyTo
,	@EmailSubject = @EmailSubject
,	@EmailBody = @EmailBody
,	@EmailAttachmentNames = @EmailAttachmentNames
,   @EmailFrom = @EmailFrom
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
go

--commit
--if	@@trancount > 0 begin
--	rollback
--end
--go

set statistics io off
set statistics time off
go
I 
}

Results {
}
*/




GO
