CREATE TABLE [FTP].[LogDetails]
(
[FLHRowID] [int] NOT NULL,
[Line] [int] NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__LogDetail__Statu__208CD6FA] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__LogDetails__Type__2180FB33] DEFAULT ((0)),
[Command] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CommandOutput] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__LogDetail__RowCr__22751F6C] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__LogDetail__RowCr__236943A5] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__LogDetail__RowMo__245D67DE] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__LogDetail__RowMo__25518C17] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [FTP].[tr_FTPLogDetails_uRowModified] on [FTP].[LogDetails] after update
as
declare
	@TranDT datetime
,	@Result int

set xact_abort off
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI.usp_Test
--- </Error Handling>

begin try
	--- <Tran Required=Yes AutoCreate=Yes TranDTParm=Yes>
	declare
		@TranCount smallint

	set	@TranCount = @@TranCount
	set	@TranDT = coalesce(@TranDT, GetDate())
	save tran @ProcName
	--- </Tran>

	---	<ArgumentValidation>

	---	</ArgumentValidation>
	
	--- <Body>
	if	not update(RowModifiedDT) begin
		--- <Update rows="*">
		set	@TableName = 'FTP.LogDetails'
		
		update
			fld
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			FTP.LogDetails fld
			join inserted i
				on i.RowID = fld.RowID
		
		select
			@Error = @@Error,
			@RowCount = @@Rowcount
		
		if	@Error != 0 begin
			set	@Result = 999999
			RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			rollback tran @ProcName
			return
		end
		--- </Update>
		
		--- </Body>
	end
end try
begin catch
	declare
		@errorName int
	,	@errorSeverity int
	,	@errorState int
	,	@errorLine int
	,	@errorProcedures sysname
	,	@errorMessage nvarchar(2048)
	,	@xact_state int
	
	select
		@errorName = error_number()
	,	@errorSeverity = error_severity()
	,	@errorState = error_state ()
	,	@errorLine = error_line()
	,	@errorProcedures = error_procedure()
	,	@errorMessage = error_message()
	,	@xact_state = xact_state()

	if	xact_state() = -1 begin
		print 'Error number: ' + convert(varchar, @errorName)
		print 'Error severity: ' + convert(varchar, @errorSeverity)
		print 'Error state: ' + convert(varchar, @errorState)
		print 'Error line: ' + convert(varchar, @errorLine)
		print 'Error procedure: ' + @errorProcedures
		print 'Error message: ' + @errorMessage
		print 'xact_state: ' + convert(varchar, @xact_state)
		
		rollback transaction
	end
	else begin
		/*	Capture any errors in SP Logging. */
		rollback tran @ProcName
	end
end catch

---	<Return>
set	@Result = 0
return
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

begin transaction Test
go

insert
	FTP.LogDetails
...

update
	...
from
	FTP.LogDetails
...

delete
	...
from
	FTP.LogDetails
...
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
ALTER TABLE [FTP].[LogDetails] ADD CONSTRAINT [PK__LogDetai__FFEE74512C3F426D] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FTP].[LogDetails] ADD CONSTRAINT [UQ__LogDetai__3D42B08D21CF7201] UNIQUE NONCLUSTERED  ([FLHRowID], [Line]) ON [PRIMARY]
GO
ALTER TABLE [FTP].[LogDetails] ADD CONSTRAINT [FK__LogDetail__FLHRo__1F98B2C1] FOREIGN KEY ([FLHRowID]) REFERENCES [FTP].[LogHeaders] ([RowID])
GO
