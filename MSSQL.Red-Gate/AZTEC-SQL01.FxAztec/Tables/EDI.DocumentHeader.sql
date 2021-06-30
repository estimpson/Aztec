CREATE TABLE [EDI].[DocumentHeader]
(
[ProcessGUID] [uniqueidentifier] NOT NULL,
[DocumentGUID] [uniqueidentifier] NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__DocumentH__Statu__6723122E] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__DocumentHe__Type__68173667] DEFAULT ((0)),
[ReceiveDT] [datetime] NOT NULL,
[TradingPartner] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DocType] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Version] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ICN] [int] NULL,
[TransactionSetPurposeCode] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReferenceIdentification] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocumentDate] [date] NULL,
[ScheduleTypeQualifier] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HorizonStartDate] [date] NULL,
[HorizonEndDate] [date] NULL,
[ReleaseNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReferenceIdentification2] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ContractNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PurchaseOrderNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ScheduleQuantityQualifier] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProductGroup] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomReference] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__DocumentH__RowCr__690B5AA0] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NULL CONSTRAINT [DF__DocumentH__RowCr__69FF7ED9] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__DocumentH__RowMo__6AF3A312] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NULL CONSTRAINT [DF__DocumentH__RowMo__6BE7C74B] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [EDI].[tr_DocumentHeader_uRowModified] on [EDI].[DocumentHeader] after update
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
		set	@TableName = 'EDI.DocumentHeader'
		
		update
			ssh
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI.DocumentHeader ssh
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
	EDI.DocumentHeader
...

update
	...
from
	EDI.DocumentHeader
...

delete
	...
from
	EDI.DocumentHeader
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
ALTER TABLE [EDI].[DocumentHeader] ADD CONSTRAINT [PK__Document__FFEE7451DD1F2B06] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [EDI].[DocumentHeader] ADD CONSTRAINT [UQ__Document__34B054684680B7D1] UNIQUE NONCLUSTERED  ([ProcessGUID]) ON [PRIMARY]
GO
