CREATE TABLE [EDI].[ProcessReport]
(
[Status] [int] NOT NULL CONSTRAINT [DF__ProcessRe__Statu__35DCF99B] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__ProcessRep__Type__36D11DD4] DEFAULT ((0)),
[ProcedureName] [sys].[sysname] NOT NULL,
[TradingPartner] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocumentType] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AlertType] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReleaseNo] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToCode] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConsigneeCode] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromCode] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPart] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPO] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerModelYear] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TranDT] [datetime] NOT NULL,
[Description] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__ProcessRe__RowCr__37C5420D] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ProcessRe__RowCr__38B96646] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__ProcessRe__RowMo__39AD8A7F] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ProcessRe__RowMo__3AA1AEB8] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [EDI].[tr_ProcessReport_uRowModified] on [EDI].[ProcessReport] after update
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

set	@ProcName = schema_name(objectproperty(@@procid, 'SchemaID')) + '.' + object_name(@@procid)  -- e.g. EDI.usp_Test
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
		set	@TableName = 'EDI.ProcessReport'
		
		update
			rp
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI.ProcessReport rp
			join inserted i
				on i.RowID = rp.RowID
		
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
	EDI.ProcessReport
...

update
	...
from
	EDI.ProcessReport
...

delete
	...
from
	EDI.ProcessReport
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
ALTER TABLE [EDI].[ProcessReport] ADD CONSTRAINT [PK__ProcessR__FFEE74511FE20945] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
