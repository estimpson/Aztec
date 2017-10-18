CREATE TABLE [EDIToyota].[ManifestDetailsDeleted]
(
[PickupID] [int] NULL,
[ManifestNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPart] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__ManifestD__Statu__5E6D3B3E] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__ManifestDe__Type__5F615F77] DEFAULT ((0)),
[ReturnableContainer] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Quantity] [int] NOT NULL,
[Racks] [int] NOT NULL,
[OrderNo] [int] NULL,
[Plant] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OrigPickupID] [int] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__ManifestD__RowCr__6149A7E9] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ManifestD__RowCr__623DCC22] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__ManifestD__RowMo__6331F05B] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ManifestD__RowMo__64261494] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [EDIToyota].[tr_ManifestDetailsDeleted_uRowModified] on [EDIToyota].[ManifestDetailsDeleted] after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDIToyota.usp_Test
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
		set	@TableName = 'EDIToyota.ManifestDetailsDeleted'
		
		update
			mdd
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDIToyota.ManifestDetailsDeleted mdd
			join inserted i
				on i.RowID = mdd.RowID
		
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
	EDIToyota.ManifestDetailsDeleted
...

update
	...
from
	EDIToyota.ManifestDetailsDeleted
...

delete
	...
from
	EDIToyota.ManifestDetailsDeleted
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
ALTER TABLE [EDIToyota].[ManifestDetailsDeleted] ADD CONSTRAINT [PK__Manifest__FFEE745158B461E8] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [EDIToyota].[ManifestDetailsDeleted] ADD CONSTRAINT [UQ__Manifest__F3905BCD5B90CE93] UNIQUE NONCLUSTERED  ([PickupID], [ManifestNumber], [CustomerPart]) ON [PRIMARY]
GO
ALTER TABLE [EDIToyota].[ManifestDetailsDeleted] ADD CONSTRAINT [FK__ManifestD__OrigP__1D37A21A] FOREIGN KEY ([OrigPickupID]) REFERENCES [EDIToyota].[Pickups] ([RowID])
GO
ALTER TABLE [EDIToyota].[ManifestDetailsDeleted] ADD CONSTRAINT [FK__ManifestD__OrigP__605583B0] FOREIGN KEY ([OrigPickupID]) REFERENCES [EDIToyota].[Pickups] ([RowID])
GO
ALTER TABLE [EDIToyota].[ManifestDetailsDeleted] ADD CONSTRAINT [FK__ManifestD__Picku__1E2BC653] FOREIGN KEY ([PickupID]) REFERENCES [EDIToyota].[Pickups] ([RowID])
GO
ALTER TABLE [EDIToyota].[ManifestDetailsDeleted] ADD CONSTRAINT [FK__ManifestD__Picku__5D791705] FOREIGN KEY ([PickupID]) REFERENCES [EDIToyota].[Pickups] ([RowID])
GO
