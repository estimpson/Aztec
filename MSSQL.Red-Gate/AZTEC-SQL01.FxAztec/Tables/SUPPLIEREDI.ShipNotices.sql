CREATE TABLE [SUPPLIEREDI].[ShipNotices]
(
[Status] [int] NOT NULL CONSTRAINT [DF__ShipNotic__Statu__6E2E39F8] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__ShipNotice__Type__6F225E31] DEFAULT ((0)),
[RawDocumentGUID] [uniqueidentifier] NOT NULL,
[ShipperID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BillOfLadingNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipDT] [datetime] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__ShipNotic__RowCr__7016826A] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipNotic__RowCr__710AA6A3] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__ShipNotic__RowMo__71FECADC] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipNotic__RowMo__72F2EF15] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [SUPPLIEREDI].[tr_ShipNotices_uRowModified] on [SUPPLIEREDI].[ShipNotices] after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. SUPPLIEREDI.usp_Test
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
		set	@TableName = 'SUPPLIEREDI.ShipNotices'
		
		update
			sn
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			SUPPLIEREDI.ShipNotices sn
			join inserted i
				on i.RowID = sn.RowID
		
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
	SUPPLIEREDI.ShipNotices
...

update
	...
from
	SUPPLIEREDI.ShipNotices
...

delete
	...
from
	SUPPLIEREDI.ShipNotices
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
ALTER TABLE [SUPPLIEREDI].[ShipNotices] ADD CONSTRAINT [PK__ShipNoti__FFEE745160732179] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [SUPPLIEREDI].[ShipNotices] ADD CONSTRAINT [UQ__ShipNoti__ABAFD68216D5A615] UNIQUE NONCLUSTERED  ([RawDocumentGUID]) ON [PRIMARY]
GO
GRANT DELETE ON  [SUPPLIEREDI].[ShipNotices] TO [SupplierPortal]
GO
GRANT INSERT ON  [SUPPLIEREDI].[ShipNotices] TO [SupplierPortal]
GO
GRANT SELECT ON  [SUPPLIEREDI].[ShipNotices] TO [SupplierPortal]
GO
GRANT UPDATE ON  [SUPPLIEREDI].[ShipNotices] TO [SupplierPortal]
GO
