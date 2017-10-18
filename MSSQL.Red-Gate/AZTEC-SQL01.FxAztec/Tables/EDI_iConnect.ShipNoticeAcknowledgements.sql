CREATE TABLE [EDI_iConnect].[ShipNoticeAcknowledgements]
(
[RawDocumentGUID] [uniqueidentifier] NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__ShipNotic__Statu__32470242] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__ShipNotice__Type__333B267B] DEFAULT ((0)),
[DocumentImportDT] [datetime] NULL,
[ASN_Number] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipDate] [datetime] NULL,
[SupplierCode] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AcknowledgementStatus] [int] NULL,
[ValidationOutput] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__ShipNotic__RowCr__342F4AB4] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipNotic__RowCr__35236EED] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__ShipNotic__RowMo__36179326] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipNotic__RowMo__370BB75F] DEFAULT (suser_name())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [EDI_iConnect].[tr_ShipNoticeAcknowledgements_uRowModified] on [EDI_iConnect].[ShipNoticeAcknowledgements] after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI_iConnect.usp_Test
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
		set	@TableName = 'EDI_iConnect.ShipNoticeAcknowledgements'
		
		update
			sna
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI_iConnect.ShipNoticeAcknowledgements sna
			join inserted i
				on i.RowID = sna.RowID
		
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
	EDI_iConnect.ShipNoticeAcknowledgements
...

update
	...
from
	EDI_iConnect.ShipNoticeAcknowledgements
...

delete
	...
from
	EDI_iConnect.ShipNoticeAcknowledgements
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
ALTER TABLE [EDI_iConnect].[ShipNoticeAcknowledgements] ADD CONSTRAINT [PK__ShipNoti__FFEE74513F2D3C6E] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [EDI_iConnect].[ShipNoticeAcknowledgements] ADD CONSTRAINT [UQ__ShipNoti__ABAFD682FA95C078] UNIQUE NONCLUSTERED  ([RawDocumentGUID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ShipNoticeAcknowledgements_1] ON [EDI_iConnect].[ShipNoticeAcknowledgements] ([Status]) ON [PRIMARY]
GO
