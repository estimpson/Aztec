CREATE TABLE [EDI3060].[ShipScheduleHeaders]
(
[Status] [int] NOT NULL CONSTRAINT [DF__ShipSched__Statu__4A18FC72] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__ShipSchedu__Type__4B0D20AB] DEFAULT ((0)),
[RawDocumentGUID] [uniqueidentifier] NULL,
[DocumentImportDT] [datetime] NULL,
[TradingPartner] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocType] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Version] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Release] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ControlNumber] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocumentDT] [datetime] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__ShipSched__RowCr__4C0144E4] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipSched__RowCr__4CF5691D] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__ShipSched__RowMo__4DE98D56] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipSched__RowMo__4EDDB18F] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [EDI3060].[tr_ShipScheduleHeaders_uRowModified] on [EDI3060].[ShipScheduleHeaders] after update
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

set	@ProcName = schema_name(objectproperty(@@procid, 'SchemaID')) + '.' + object_name(@@procid)  -- e.g. EDI3060.usp_Test
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
		set	@TableName = 'EDI3060.ShipScheduleHeaders'
		
		update
			ssh
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI3060.ShipScheduleHeaders ssh
			join inserted i
				on i.RowID = ssh.RowID
		
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
	EDI3060.ShipScheduleHeaders
...

update
	...
from
	EDI3060.ShipScheduleHeaders
...

delete
	...
from
	EDI3060.ShipScheduleHeaders
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
ALTER TABLE [EDI3060].[ShipScheduleHeaders] ADD CONSTRAINT [PK__ShipSche__FFEE74514EE155C4] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
