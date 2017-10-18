CREATE TABLE [dbo].[InventoryControl_QualityBatchObjects]
(
[QualityBatchNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Line] [float] NULL,
[Serial] [int] NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__Inventory__Statu__77D73C2F] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__InventoryC__Type__78CB6068] DEFAULT ((0)),
[Part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OriginalQuantity] [numeric] (20, 6) NOT NULL,
[Unit] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OriginalStatus] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[NewStatus] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ScrapQuantity] [numeric] (20, 6) NULL,
[Notes] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Inventory__RowCr__79BF84A1] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Inventory__RowCr__7AB3A8DA] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Inventory__RowMo__7BA7CD13] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Inventory__RowMo__7C9BF14C] DEFAULT (suser_name())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[tr_InventoryControl_QualityBatchObjects_uRowModified] on [dbo].[InventoryControl_QualityBatchObjects] after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. dbo.usp_Test
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
	--- <Update rows="*">
	set	@TableName = 'dbo.InventoryControl_QualityBatchObjects'
	
	update
		icqbo
	set	RowModifiedDT = getdate()
	,	RowModifiedUser = suser_name()
	from
		dbo.InventoryControl_QualityBatchObjects icqbo
		join inserted i
			on i.RowID = icqbo.RowID
	
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
	dbo.InventoryControl_QualityBatchObjects
...

update
	...
from
	dbo.InventoryControl_QualityBatchObjects
...

delete
	...
from
	dbo.InventoryControl_QualityBatchObjects
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
ALTER TABLE [dbo].[InventoryControl_QualityBatchObjects] ADD CONSTRAINT [PK__Inventor__FFEE745074FACF84] PRIMARY KEY NONCLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[InventoryControl_QualityBatchObjects] ADD CONSTRAINT [UQ__Inventor__CC6BA9806F41F62E] UNIQUE CLUSTERED  ([QualityBatchNumber], [Line]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[InventoryControl_QualityBatchObjects] ADD CONSTRAINT [UQ__Inventor__8649DA4E721E62D9] UNIQUE NONCLUSTERED  ([QualityBatchNumber], [Serial]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[InventoryControl_QualityBatchObjects] ADD CONSTRAINT [FK__Inventory__Quali__505F1309] FOREIGN KEY ([QualityBatchNumber]) REFERENCES [dbo].[InventoryControl_QualityBatchHeaders] ([QualityBatchNumber])
GO
