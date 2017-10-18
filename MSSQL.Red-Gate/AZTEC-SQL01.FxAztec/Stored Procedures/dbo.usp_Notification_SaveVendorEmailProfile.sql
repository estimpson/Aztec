SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


Create procedure [dbo].[usp_Notification_SaveVendorEmailProfile]
	@VendorCode varchar(10)
,	@EmailTo nvarchar(4000)
,	@EmailCC nvarchar(4000)
,	@EmailReplyTo nvarchar(4000)
,	@EmailSubject nvarchar(4000)
,	@EmailBody nvarchar(4000)
,	@EmailAttachmentNames nvarchar(4000)
,	@EmailFrom nvarchar(4000)
,	@TranDT datetime out
,	@Result integer out
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
/*	Get or create the Email profile ID for the passed arguments. */
declare
	@ProfileID int
	
set	@ProfileID =
	(	select
			nep.RowID
		from
			dbo.Notification_EmailProfiles nep
		where
			coalesce(nep.EmailTo, '~') = coalesce(@EmailTo, '~')
			and coalesce(nep.EmailCC, '~') = coalesce(@EmailCC, '~')
			and coalesce(nep.EmailReplyTo, '~') = coalesce(@EmailReplyTo, '~')
			and coalesce(nep.EmailSubject, '~') = coalesce(@EmailSubject, '~')
			and coalesce(nep.EmailBody, '~') = coalesce(@EmailBody, '~')
			and coalesce(nep.EmailAttachmentNames, '~') = coalesce(@EmailAttachmentNames, '~')
			and coalesce(nep.EmailFrom, '~') = coalesce(@EmailFrom, '~')
	)

if	@ProfileID is null begin
	--- <Insert rows="1">
	set	@TableName = 'dbo.Notification_EmailProfiles'
	
	insert
		dbo.Notification_EmailProfiles
	(	EmailTo
	,	EmailCC
	,	EmailReplyTo
	,	EmailSubject
	,	EmailBody
	,	EmailAttachmentNames
	,	EmailFrom
	)
	select
		EmailTo = @EmailTo
	,	EmailCC = @EmailCC
	,	EmailReplyTo = @EmailReplyTo
	,	EmailSubject = @EmailSubject
	,	EmailBody = @EmailBody
	,	EmailAttachmentNames = @EmailAttachmentNames
	,	EmailFrom = @EmailFrom
		
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount != 1 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Insert>
	
	set	@ProfileID = scope_identity()
end

/*	Insert or update the vendor's Email profile. */
--- <Update rows="1">
set	@TableName = 'dbo.Notification_VendorEmailProfile'

update
	nvep
set
	ProfileID = @ProfileID
from
	dbo.Notification_VendorEmailProfile nvep
where
	nvep.VendorCode = @VendorCode

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran @ProcName
	return
end
if	@RowCount != 1 begin
	--- <Insert rows="1">
	set	@TableName = 'dbo.Notification_VendorEmailProfile'
	
	insert
		dbo.Notification_VendorEmailProfile
	(	VendorCode
	,	ProfileID
	)
	select
		VendorCode = @VendorCode
	,	ProfileID = @ProfileID
	
	select
		@Error = @@Error,
		@RowCount = @@Rowcount
	
	if	@Error != 0 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
		rollback tran @ProcName
		return
	end
	if	@RowCount != 1 begin
		set	@Result = 999999
		RAISERROR ('Error inserting into table %s in procedure %s.  Rows inserted: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
		rollback tran @ProcName
		return
	end
	--- </Insert>	
end
--- </Update>
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
	@VendorCode nvarchar(10)
,	@EmailTo nvarchar(4000)
,	@EmailCC nvarchar(4000)
,	@EmailReplyTo nvarchar(4000)
,	@EmailSubject nvarchar(4000)
,	@EmailBody nvarchar(4000)
,	@EmailAttachmentNames nvarchar(4000)
,	@EmailFrom nvarchar(4000)

set	@VendorCode = 'FASTB0010'
set	@EmailTo = '1@2.3'
set	@EmailCC = '1@2.3'
set	@EmailReplyTo = 'admin@fore-thought.com'
set	@EmailSubject = 'SendEmail'
set	@EmailBody = 'test fxAztecTest.dbo.usp_Notification_SaveVendorEmailProfile'
set	@EmailAttachmentNames = null
set	@EmailFrom = 'NotificationSystem@fore-thought.com'

begin transaction Test

declare
	@ProcReturn integer
,	@TranDT datetime
,	@ProcResult integer
,	@Error integer

execute
	dbo.usp_Notification_SaveVendorEmailProfile
	@VendorCode = @VendorCode
,	@EmailTo = @EmailTo
,	@EmailCC = @EmailCC
,	@EmailReplyTo = @EmailReplyTo
,	@EmailSubject = @EmailSubject
,	@EmailBody = @EmailBody
,	@EmailAttachmentNames = @EmailAttachmentNames
,	@EmailFrom = @EmailFrom
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@error

select
	@Error, @ProcReturn, @TranDT, @ProcResult
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
