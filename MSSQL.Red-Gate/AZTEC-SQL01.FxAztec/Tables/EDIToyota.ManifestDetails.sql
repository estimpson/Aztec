CREATE TABLE [EDIToyota].[ManifestDetails]
(
[PickupID] [int] NULL,
[ManifestNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPart] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__ManifestD__Statu__2752107E] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__ManifestDe__Type__284634B7] DEFAULT ((0)),
[ReturnableContainer] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Quantity] [int] NOT NULL,
[Racks] [int] NOT NULL,
[OrderNo] [int] NULL,
[Plant] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OrigPickupID] [int] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__ManifestD__RowCr__2A2E7D29] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ManifestD__RowCr__2B22A162] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__ManifestD__RowMo__2C16C59B] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ManifestD__RowMo__2D0AE9D4] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [EDIToyota].[tr_ManifestDetails_uRowModified] on [EDIToyota].[ManifestDetails] after update
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
		set	@TableName = 'EDIToyota.ManifestDetails'
		
		update
			md
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDIToyota.ManifestDetails md
			join inserted i
				on i.RowID = md.RowID
		
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
	EDIToyota.ManifestDetails
...

update
	...
from
	EDIToyota.ManifestDetails
...

delete
	...
from
	EDIToyota.ManifestDetails
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
ALTER TABLE [EDIToyota].[ManifestDetails] ADD CONSTRAINT [PK__Manifest__FFEE745121993728] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [EDIToyota].[ManifestDetails] ADD CONSTRAINT [UQ__Manifest__F3905BCD2475A3D3] UNIQUE NONCLUSTERED  ([PickupID], [ManifestNumber], [CustomerPart]) ON [PRIMARY]
GO
ALTER TABLE [EDIToyota].[ManifestDetails] ADD CONSTRAINT [FK__ManifestD__OrigP__1B4F59A8] FOREIGN KEY ([OrigPickupID]) REFERENCES [EDIToyota].[Pickups] ([RowID])
GO
ALTER TABLE [EDIToyota].[ManifestDetails] ADD CONSTRAINT [FK__ManifestD__OrigP__293A58F0] FOREIGN KEY ([OrigPickupID]) REFERENCES [EDIToyota].[Pickups] ([RowID])
GO
ALTER TABLE [EDIToyota].[ManifestDetails] ADD CONSTRAINT [FK__ManifestD__Picku__1C437DE1] FOREIGN KEY ([PickupID]) REFERENCES [EDIToyota].[Pickups] ([RowID])
GO
ALTER TABLE [EDIToyota].[ManifestDetails] ADD CONSTRAINT [FK__ManifestD__Picku__265DEC45] FOREIGN KEY ([PickupID]) REFERENCES [EDIToyota].[Pickups] ([RowID])
GO
