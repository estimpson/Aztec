CREATE TABLE [SPORTAL].[SupplierObjectBatches]
(
[Status] [int] NOT NULL CONSTRAINT [DF__SupplierO__Statu__6980C3AF] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__SupplierOb__Type__6A74E7E8] DEFAULT ((0)),
[SupplierCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SupplierPartCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[InternalPartCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[QuantityPerObject] [numeric] (20, 6) NOT NULL,
[ObjectCount] [int] NOT NULL,
[LotNumber] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FirstSerial] [int] NOT NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__SupplierO__RowCr__6B690C21] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__SupplierO__RowCr__6C5D305A] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__SupplierO__RowMo__6D515493] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__SupplierO__RowMo__6E4578CC] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [SPORTAL].[tr_SupplierObjectBatches_uRowModified] on [SPORTAL].[SupplierObjectBatches] after update
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
		set	@TableName = 'SPORTAL.SupplierObjectBatches'
		
		update
			sob
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			SPORTAL.SupplierObjectBatches sob
			join inserted i
				on i.RowID = sob.RowID
		
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
	SPORTAL.SupplierObjectBatches
...

update
	...
from
	SPORTAL.SupplierObjectBatches
...

delete
	...
from
	SPORTAL.SupplierObjectBatches
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
ALTER TABLE [SPORTAL].[SupplierObjectBatches] ADD CONSTRAINT [PK__Supplier__FFEE745118D69F7C] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [SPORTAL].[SupplierObjectBatches] ADD CONSTRAINT [UQ__Supplier__FBB6EFBC5435799A] UNIQUE NONCLUSTERED  ([FirstSerial]) ON [PRIMARY]
GO
GRANT DELETE ON  [SPORTAL].[SupplierObjectBatches] TO [SupplierPortal]
GO
GRANT INSERT ON  [SPORTAL].[SupplierObjectBatches] TO [SupplierPortal]
GO
GRANT SELECT ON  [SPORTAL].[SupplierObjectBatches] TO [SupplierPortal]
GO
GRANT UPDATE ON  [SPORTAL].[SupplierObjectBatches] TO [SupplierPortal]
GO
