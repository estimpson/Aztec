CREATE TABLE [SPORTAL].[SupplierObjects]
(
[Serial] [int] NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__SupplierO__Statu__3AE5D057] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__SupplierOb__Type__3BD9F490] DEFAULT ((0)),
[SupplierObjectBatch] [int] NOT NULL,
[Quantity] [numeric] (20, 6) NOT NULL,
[LotNumber] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipperNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__SupplierO__RowCr__3EB6613B] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__SupplierO__RowCr__3FAA8574] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__SupplierO__RowMo__409EA9AD] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__SupplierO__RowMo__4192CDE6] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [SPORTAL].[tr_SupplierObjects_uRowModified] on [SPORTAL].[SupplierObjects] after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SPORTAL.usp_Test
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
		set	@TableName = 'SPORTAL.SupplierObjects'
		
		update
			so
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			SPORTAL.SupplierObjects so
			join inserted i
				on i.RowID = so.RowID
		
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
	SPORTAL.SupplierObjects
...

update
	...
from
	SPORTAL.SupplierObjects
...

delete
	...
from
	SPORTAL.SupplierObjects
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
ALTER TABLE [SPORTAL].[SupplierObjects] ADD CONSTRAINT [PK__Supplier__FFEE7451D448B68D] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [SPORTAL].[SupplierObjects] ADD CONSTRAINT [UQ__Supplier__1A00E0931D396131] UNIQUE NONCLUSTERED  ([Serial]) ON [PRIMARY]
GO
ALTER TABLE [SPORTAL].[SupplierObjects] ADD CONSTRAINT [FK__SupplierO__Shipp__3DC23D02] FOREIGN KEY ([ShipperNumber]) REFERENCES [SPORTAL].[SupplierShipments] ([ShipperNumber])
GO
ALTER TABLE [SPORTAL].[SupplierObjects] ADD CONSTRAINT [FK__SupplierO__Suppl__3CCE18C9] FOREIGN KEY ([SupplierObjectBatch]) REFERENCES [SPORTAL].[SupplierObjectBatches] ([RowID])
GO
GRANT DELETE ON  [SPORTAL].[SupplierObjects] TO [SupplierPortal]
GO
GRANT INSERT ON  [SPORTAL].[SupplierObjects] TO [SupplierPortal]
GO
GRANT SELECT ON  [SPORTAL].[SupplierObjects] TO [SupplierPortal]
GO
GRANT UPDATE ON  [SPORTAL].[SupplierObjects] TO [SupplierPortal]
GO
