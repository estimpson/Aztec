CREATE TABLE [dbo].[Router_BillOfMaterials]
(
[OutputPart] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[InputPart] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Suffix] [int] NULL,
[StartDT] [datetime] NOT NULL,
[EndDT] [datetime] NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__Router_Bi__Statu__682AE44B] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Router_Bil__Type__691F0884] DEFAULT ((0)),
[Quantity] [numeric] (20, 6) NOT NULL,
[UnitMeasure] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StdQuantity] [numeric] (20, 6) NOT NULL,
[ScrapFactor] [numeric] (20, 6) NOT NULL,
[EngineeringLevel] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Substitute] [bit] NULL CONSTRAINT [DF__Router_Bi__Subst__6A132CBD] DEFAULT ((0)),
[ReferenceNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Note] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Router_Bi__RowCr__6B0750F6] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Router_Bi__RowCr__6BFB752F] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Router_Bi__RowMo__6CEF9968] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Router_Bi__RowMo__6DE3BDA1] DEFAULT (suser_name())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[tr_Router_BillOfMaterials_uRowModified] on [dbo].[Router_BillOfMaterials] after update
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
	set	@TableName = 'dbo.Router_BillOfMaterials'
	
	update
		bom
	set	RowModifiedDT = getdate()
	,	RowModifiedUser = suser_name()
	from
		dbo.Router_BillOfMaterials bom
		join inserted i
			on i.RowID = bom.RowID
	
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
	dbo.Router_BillOfMaterials
...

update
	...
from
	dbo.Router_BillOfMaterials
...

delete
	...
from
	dbo.Router_BillOfMaterials
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
ALTER TABLE [dbo].[Router_BillOfMaterials] ADD CONSTRAINT [PK__Router_B__FFEE7451C11BF988] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Router_BillOfMaterials] ADD CONSTRAINT [UQ__Router_B__DC22007C1F375FEB] UNIQUE NONCLUSTERED  ([OutputPart], [InputPart], [Suffix], [StartDT], [Type]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Router_BillOfMaterials] ADD CONSTRAINT [FK__Router_Bi__Input__6736C012] FOREIGN KEY ([InputPart]) REFERENCES [dbo].[part] ([part])
GO
ALTER TABLE [dbo].[Router_BillOfMaterials] ADD CONSTRAINT [FK__Router_Bi__Outpu__66429BD9] FOREIGN KEY ([OutputPart]) REFERENCES [dbo].[part] ([part])
GO
