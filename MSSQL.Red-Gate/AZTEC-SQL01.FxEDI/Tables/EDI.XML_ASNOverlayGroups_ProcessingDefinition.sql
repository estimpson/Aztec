CREATE TABLE [EDI].[XML_ASNOverlayGroups_ProcessingDefinition]
(
[ASNOverlayGroup] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__XML_ASNOv__Statu__75035A77] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__XML_ASNOve__Type__75F77EB0] DEFAULT ((0)),
[ProcessingProcedureSchema] [sys].[sysname] NULL,
[ProcessingProcedureName] [sys].[sysname] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__XML_ASNOv__RowCr__76EBA2E9] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__XML_ASNOv__RowCr__77DFC722] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__XML_ASNOv__RowMo__78D3EB5B] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__XML_ASNOv__RowMo__79C80F94] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [EDI].[tr_XML_ASNOverlayGroups_ProcessingDefinition_uRowModified] on [EDI].[XML_ASNOverlayGroups_ProcessingDefinition] after update
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

set	@ProcName = schema_name(objectproperty(@@procid, 'SchemaID')) + '.' + object_name(@@procid)  -- e.g. EDI.usp_Test
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
		set	@TableName = 'EDI.XML_ASNOverlayGroups_ProcessingDefinition'
		
		update
			xarf
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI.XML_ASNOverlayGroups_ProcessingDefinition xarf
			join inserted i
				on i.RowID = xarf.RowID
		
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
	EDI.XML_ASNOverlayGroups_ProcessingDefinition
...

update
	...
from
	EDI.XML_ASNOverlayGroups_ProcessingDefinition
...

delete
	...
from
	EDI.XML_ASNOverlayGroups_ProcessingDefinition
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
ALTER TABLE [EDI].[XML_ASNOverlayGroups_ProcessingDefinition] ADD CONSTRAINT [PK__XML_ASNO__FFEE7451CAD3A293] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [EDI].[XML_ASNOverlayGroups_ProcessingDefinition] ADD CONSTRAINT [UQ__XML_ASNO__43FF4580FA73B5B7] UNIQUE NONCLUSTERED  ([ASNOverlayGroup]) ON [PRIMARY]
GO
