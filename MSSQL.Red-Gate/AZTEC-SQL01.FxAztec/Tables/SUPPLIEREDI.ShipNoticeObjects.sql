CREATE TABLE [SUPPLIEREDI].[ShipNoticeObjects]
(
[Status] [int] NOT NULL CONSTRAINT [DF__ShipNotic__Statu__6A289EEA] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__ShipNotice__Type__6B1CC323] DEFAULT ((0)),
[RawDocumentGUID] [uniqueidentifier] NOT NULL,
[SupplierPart] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SupplierSerial] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SupplierParentSerial] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SupplierPackageType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SupplierLot] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ObjectQuantity] [numeric] (20, 6) NULL,
[PartCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ObjectSerial] [int] NULL,
[ObjectParentSerial] [int] NULL,
[ObjectPackageType] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__ShipNotic__RowCr__6D050B95] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipNotic__RowCr__6DF92FCE] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__ShipNotic__RowMo__6EED5407] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipNotic__RowMo__6FE17840] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [SUPPLIEREDI].[tr_ShipNoticeObjects_uRowModified] on [SUPPLIEREDI].[ShipNoticeObjects] after update
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
		set	@TableName = 'SUPPLIEREDI.ShipNoticeObjects'
		
		update
			sno
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			SUPPLIEREDI.ShipNoticeObjects sno
			join inserted i
				on i.RowID = sno.RowID
		
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
	SUPPLIEREDI.ShipNoticeObjects
...

update
	...
from
	SUPPLIEREDI.ShipNoticeObjects
...

delete
	...
from
	SUPPLIEREDI.ShipNoticeObjects
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
ALTER TABLE [SUPPLIEREDI].[ShipNoticeObjects] ADD CONSTRAINT [PK__ShipNoti__FFEE7451B472251C] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [SUPPLIEREDI].[ShipNoticeObjects] ADD CONSTRAINT [FK__ShipNoticeObject__70D59C79] FOREIGN KEY ([RawDocumentGUID], [SupplierPart]) REFERENCES [SUPPLIEREDI].[ShipNoticeLines] ([RawDocumentGUID], [SupplierPart])
GO
ALTER TABLE [SUPPLIEREDI].[ShipNoticeObjects] ADD CONSTRAINT [FK__ShipNotic__RawDo__6C10E75C] FOREIGN KEY ([RawDocumentGUID]) REFERENCES [SUPPLIEREDI].[ShipNotices] ([RawDocumentGUID])
GO
GRANT DELETE ON  [SUPPLIEREDI].[ShipNoticeObjects] TO [SupplierPortal]
GO
GRANT INSERT ON  [SUPPLIEREDI].[ShipNoticeObjects] TO [SupplierPortal]
GO
GRANT SELECT ON  [SUPPLIEREDI].[ShipNoticeObjects] TO [SupplierPortal]
GO
GRANT UPDATE ON  [SUPPLIEREDI].[ShipNoticeObjects] TO [SupplierPortal]
GO
