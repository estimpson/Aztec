CREATE TABLE [IPTAG].[StandardTagOperations]
(
[FormatName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__StandardT__Statu__7518FE6E] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__StandardTa__Type__760D22A7] DEFAULT ((0)),
[RowNum] [tinyint] NOT NULL,
[OperationNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OperationName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowVersion] [timestamp] NOT NULL,
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__StandardT__RowCr__770146E0] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__StandardT__RowCr__77F56B19] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__StandardT__RowMo__78E98F52] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__StandardT__RowMo__79DDB38B] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [IPTAG].[tr_StandardTagOperations_uRowModified] on [IPTAG].[StandardTagOperations] after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. IPTAG.usp_Test
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
		set	@TableName = 'IPTAG.StandardTagOperations'
		
		update
			sto
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			IPTAG.StandardTagOperations sto
			join inserted i
				on i.RowID = sto.RowID
		
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
	IPTAG.StandardTagOperations
...

update
	...
from
	IPTAG.StandardTagOperations
...

delete
	...
from
	IPTAG.StandardTagOperations
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
ALTER TABLE [IPTAG].[StandardTagOperations] ADD CONSTRAINT [PK__Standard__FFEE74513E09B41A] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [IPTAG].[StandardTagOperations] ADD CONSTRAINT [UQ__Standard__FAEEB1A10430B528] UNIQUE NONCLUSTERED  ([FormatName], [RowNum]) ON [PRIMARY]
GO
ALTER TABLE [IPTAG].[StandardTagOperations] ADD CONSTRAINT [FK__StandardT__Forma__7424DA35] FOREIGN KEY ([FormatName]) REFERENCES [IPTAG].[StandardTagHeader] ([FormatName]) ON DELETE CASCADE ON UPDATE CASCADE
GO
