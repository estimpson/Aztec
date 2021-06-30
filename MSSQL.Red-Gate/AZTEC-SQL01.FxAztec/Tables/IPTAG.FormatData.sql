CREATE TABLE [IPTAG].[FormatData]
(
[FormatName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__FormatDat__Statu__19C07338] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__FormatData__Type__1AB49771] DEFAULT ((0)),
[RowNum] [int] NOT NULL,
[ColNum] [int] NOT NULL,
[Value] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TMargin] [smallint] NOT NULL CONSTRAINT [DF__FormatDat__TMarg__1BA8BBAA] DEFAULT ((0)),
[RMargin] [smallint] NOT NULL CONSTRAINT [DF__FormatDat__RMarg__1C9CDFE3] DEFAULT ((0)),
[BMargin] [smallint] NOT NULL CONSTRAINT [DF__FormatDat__BMarg__1D91041C] DEFAULT ((0)),
[LMargin] [smallint] NOT NULL CONSTRAINT [DF__FormatDat__LMarg__1E852855] DEFAULT ((0)),
[HAlign] [tinyint] NOT NULL CONSTRAINT [DF__FormatDat__HAlig__1F794C8E] DEFAULT ((0)),
[FontSize] [tinyint] NOT NULL CONSTRAINT [DF__FormatDat__FontS__206D70C7] DEFAULT ((14)),
[FontWeight] [int] NOT NULL CONSTRAINT [DF__FormatDat__FontW__21619500] DEFAULT ((400)),
[RowSpan] [tinyint] NOT NULL CONSTRAINT [DF__FormatDat__RowSp__2255B939] DEFAULT ((1)),
[ColSpan] [tinyint] NOT NULL CONSTRAINT [DF__FormatDat__ColSp__2349DD72] DEFAULT ((1)),
[TBorder] [tinyint] NOT NULL CONSTRAINT [DF__FormatDat__TBord__243E01AB] DEFAULT ((0)),
[RBorder] [tinyint] NOT NULL CONSTRAINT [DF__FormatDat__RBord__253225E4] DEFAULT ((0)),
[BBorder] [tinyint] NOT NULL CONSTRAINT [DF__FormatDat__BBord__26264A1D] DEFAULT ((0)),
[LBorder] [tinyint] NOT NULL CONSTRAINT [DF__FormatDat__LBord__271A6E56] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__FormatDat__RowCr__280E928F] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__FormatDat__RowCr__2902B6C8] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__FormatDat__RowMo__29F6DB01] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__FormatDat__RowMo__2AEAFF3A] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [IPTAG].[tr_FormatData_uRowModified] on [IPTAG].[FormatData] after update
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

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. IPTAG.usp_Test
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
		set	@TableName = 'IPTAG.FormatData'
		
		update
			fd
		set	RowModifiedDT = getdate()
		,	RowModifiedUser = suser_name()
		from
			IPTAG.FormatData fd
			join inserted i
				on i.RowID = fd.RowID
		
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
	IPTAG.FormatData
...

update
	...
from
	IPTAG.FormatData
...

delete
	...
from
	IPTAG.FormatData
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
ALTER TABLE [IPTAG].[FormatData] ADD CONSTRAINT [PK__FormatDa__FFEE7451E6CE288C] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [IPTAG].[FormatData] ADD CONSTRAINT [UQ__FormatDa__0C4200BCCD9BB053] UNIQUE NONCLUSTERED  ([FormatName], [RowNum], [ColNum]) ON [PRIMARY]
GO
ALTER TABLE [IPTAG].[FormatData] ADD CONSTRAINT [FK__FormatDat__Forma__18CC4EFF] FOREIGN KEY ([FormatName]) REFERENCES [IPTAG].[Formats] ([FormatName]) ON DELETE CASCADE ON UPDATE CASCADE
GO
