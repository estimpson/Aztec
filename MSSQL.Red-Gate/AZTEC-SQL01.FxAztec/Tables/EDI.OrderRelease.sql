CREATE TABLE [EDI].[OrderRelease]
(
[ProcessGUID] [uniqueidentifier] NOT NULL,
[DocumentGUID] [uniqueidentifier] NOT NULL,
[OrderHeaderGUID] [uniqueidentifier] NOT NULL,
[ReleaseGUID] [uniqueidentifier] NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__OrderRele__Statu__57E0CE9E] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__OrderRelea__Type__58D4F2D7] DEFAULT ((0)),
[AccumQuantity] [numeric] (20, 6) NOT NULL,
[DiscreteQuantity] [numeric] (20, 6) NOT NULL,
[ReleasePeriodCode] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReleaseTypeCode] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReleaseDateTime] [datetime] NOT NULL,
[ReleaseBeginDate] [date] NULL,
[ScheduleQuantityQualifier] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReferenceAccum] [numeric] (20, 6) NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NOT NULL CONSTRAINT [DF__OrderRele__RowCr__59C91710] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__OrderRele__RowCr__5ABD3B49] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NOT NULL CONSTRAINT [DF__OrderRele__RowMo__5BB15F82] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__OrderRele__RowMo__5CA583BB] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [EDI].[tr_OrderRelease_uRowModified] on [EDI].[OrderRelease] after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. EDI.usp_Test
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
		set	@TableName = 'EDI.OrderRelease'
		
		update
			ssoh
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			EDI.OrderRelease ssoh			join inserted i
				on i.RowID = ssoh.RowID
		
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
	EDI.OrderRelease
...

update
	...
from
	EDI.OrderRelease
...

delete
	...
from
	EDI.OrderRelease
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
ALTER TABLE [EDI].[OrderRelease] ADD CONSTRAINT [PK__OrderRel__FFEE745108FEC119] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [EDI].[OrderRelease] ADD CONSTRAINT [UQ__OrderRel__F8EFDF82554A368A] UNIQUE NONCLUSTERED  ([ReleaseGUID]) ON [PRIMARY]
GO
