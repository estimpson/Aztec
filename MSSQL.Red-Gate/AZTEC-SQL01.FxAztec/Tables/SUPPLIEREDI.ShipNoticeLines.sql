CREATE TABLE [SUPPLIEREDI].[ShipNoticeLines]
(
[Status] [int] NOT NULL CONSTRAINT [DF__ShipNotic__Statu__5FAB1077] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__ShipNotice__Type__609F34B0] DEFAULT ((0)),
[RawDocumentGUID] [uniqueidentifier] NOT NULL,
[SupplierPart] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PurchaseOrderRef] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Quantity] [numeric] (20, 6) NULL,
[PartCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PurchaseOrderNumber] [int] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__ShipNotic__RowCr__62877D22] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipNotic__RowCr__637BA15B] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__ShipNotic__RowMo__646FC594] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipNotic__RowMo__6563E9CD] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [SUPPLIEREDI].[tr_ShipNoticeLines_uRowModified] on [SUPPLIEREDI].[ShipNoticeLines] after update
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
		set	@TableName = 'SUPPLIEREDI.ShipNoticeLines'
		
		update
			snl
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			SUPPLIEREDI.ShipNoticeLines snl
			join inserted i
				on i.RowID = snl.RowID
		
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
	SUPPLIEREDI.ShipNoticeLines
...

update
	...
from
	SUPPLIEREDI.ShipNoticeLines
...

delete
	...
from
	SUPPLIEREDI.ShipNoticeLines
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
ALTER TABLE [SUPPLIEREDI].[ShipNoticeLines] ADD CONSTRAINT [PK__ShipNoti__FFEE74514FFE93E6] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [SUPPLIEREDI].[ShipNoticeLines] ADD CONSTRAINT [UQ__ShipNoti__4D558E8761D8A02D] UNIQUE NONCLUSTERED  ([RawDocumentGUID], [SupplierPart]) ON [PRIMARY]
GO
ALTER TABLE [SUPPLIEREDI].[ShipNoticeLines] ADD CONSTRAINT [FK__ShipNotic__RawDo__619358E9] FOREIGN KEY ([RawDocumentGUID]) REFERENCES [SUPPLIEREDI].[ShipNotices] ([RawDocumentGUID])
GO
