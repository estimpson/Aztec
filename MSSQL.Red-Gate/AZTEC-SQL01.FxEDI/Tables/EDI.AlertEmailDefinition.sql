CREATE TABLE [EDI].[AlertEmailDefinition]
(
[Status] [int] NOT NULL CONSTRAINT [DF__AlertEmai__Statu__3F6663D5] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__AlertEmail__Type__405A880E] DEFAULT ((0)),
[DBMailProfileName] [sys].[sysname] NOT NULL,
[RecipientsList] [sys].[sysname] NOT NULL,
[CopyList] [sys].[sysname] NOT NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__AlertEmai__RowCr__414EAC47] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__AlertEmai__RowCr__4242D080] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__AlertEmai__RowMo__4336F4B9] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__AlertEmai__RowMo__442B18F2] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [EDI].[tr_AlertEmailDefinition_uRowModified] on [EDI].[AlertEmailDefinition] after update
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
		set	@TableName = 'EDI.AlertEmailDefinition'
		
		update
			aed
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI.AlertEmailDefinition aed
			join inserted i
				on i.RowID = aed.RowID
		
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
	EDI.AlertEmailDefinition
...

update
	...
from
	EDI.AlertEmailDefinition
...

delete
	...
from
	EDI.AlertEmailDefinition
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
ALTER TABLE [EDI].[AlertEmailDefinition] ADD CONSTRAINT [PK__AlertEma__FFEE7451D755C762] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
