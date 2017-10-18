CREATE TABLE [dbo].[PartMaster_RelatedPartGroups]
(
[GroupGUID] [uniqueidentifier] NULL ROWGUIDCOL CONSTRAINT [DF__PartMaste__Group__3BA25697] DEFAULT (newid()),
[PartCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__PartMaste__Statu__3D8A9F09] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__PartMaster__Type__3E7EC342] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__PartMaste__RowCr__3F72E77B] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__PartMaste__RowCr__40670BB4] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__PartMaste__RowMo__415B2FED] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__PartMaste__RowMo__424F5426] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[tr_PartMaster_RelatedPartGroups_uRowUpdated] on [dbo].[PartMaster_RelatedPartGroups] after update
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
	set	@TableName = 'dbo.PartMaster_RelatedPartGroups'
	
	update
		pmrpg
	set
		RowModifiedDT = getdate()
	,	RowModifiedUser = suser_name()
	from
		dbo.PartMaster_RelatedPartGroups pmrpg
		join inserted i
			on i.GroupGUID = pmrpg.GroupGUID
			and i.PartCode = pmrpg.PartCode

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
	dbo.PartMaster_RelatedPartGroups
...

update
	...
from
	dbo.PartMaster_RelatedPartGroups
...

delete
	...
from
	dbo.PartMaster_RelatedPartGroups
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
ALTER TABLE [dbo].[PartMaster_RelatedPartGroups] ADD CONSTRAINT [PK__PartMast__FFEE7451F7C01703] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PartMaster_RelatedPartGroups] ADD CONSTRAINT [UQ__PartMast__3B413251C72025B0] UNIQUE NONCLUSTERED  ([GroupGUID], [PartCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PartMaster_RelatedPartGroups] ADD CONSTRAINT [FK__PartMaste__PartC__3C967AD0] FOREIGN KEY ([PartCode]) REFERENCES [dbo].[part] ([part])
GO
