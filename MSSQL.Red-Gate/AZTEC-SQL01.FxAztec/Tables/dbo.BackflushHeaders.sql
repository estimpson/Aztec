CREATE TABLE [dbo].[BackflushHeaders]
(
[BackflushNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__Backflush__Backf__6BC59FAE] DEFAULT ((0)),
[WorkOrderNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WorkOrderDetailLine] [float] NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__Backflush__Statu__6CB9C3E7] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__BackflushH__Type__6DADE820] DEFAULT ((0)),
[MachineCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ToolCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PartProduced] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SerialProduced] [int] NOT NULL,
[QtyProduced] [numeric] (20, 6) NOT NULL,
[TranDT] [datetime] NOT NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Backflush__RowCr__6EA20C59] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Backflush__RowCr__6F963092] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Backflush__RowMo__708A54CB] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Backflush__RowMo__717E7904] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--exec sp_rename 'dbo.trBackflushHeaders_i', 'tr_BackflushHeaders_NumberMask'
--alter table dbo.BackflushHeaders drop constraint UQ__Backflus__1DA70F8B69DD573C
--alter table dbo.BackflushDetails drop constraint FK__Backflush__Backf__7CF02BB0
--alter table dbo.WorkOrderObjects drop constraint FK__WorkOrder__Backf__105805DF
--alter table dbo.WorkOrderObjects drop constraint FK__WorkOrder__UndoB__114C2A18

CREATE trigger [dbo].[tr_BackflushHeaders_NumberMask] on [dbo].[BackflushHeaders] for insert
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
/*	Check if any new rows require a new backflush number. */
	if	exists
			(	select
					*
				from
					inserted i
				where
					i.BackflushNumber = '0'
			) begin

/*			Get the number of new backflush numbers needed. */
		declare
			@NumberCount int

		select
			@NumberCount = Count(*)
		from
			inserted i
		where
			i.BackflushNumber = '0'

/*			Set the new backflush numbers. */
		--- <Update rows="n">

		set	@TableName = 'dbo.BackflushHeaders'

		update
			bh
		set
			bh.BackflushNumber = NewValues.NewValue
		from
			dbo.BackflushHeaders bh
			join
			(	select
					i.RowID
				,	NewValue = FT.udf_NumberFromMaskAndValue
						(	ns.NumberMask
						,	ns.NextValue + row_number() over (order by i.RowID) - 1
						,	i.RowModifiedDT
						)
				from
					inserted i
					join FT.NumberSequenceKeys nsk
						join FT.NumberSequence ns with(updlock)
							on ns.NumberSequenceID = nsk.NumberSequenceID
						on nsk.KeyName = 'dbo.BackflushHeaders.BackflushNumber'
				where
					i.BackflushNumber = '0'
			) NewValues
				on NewValues.RowID = bh.RowID

		select
			@Error = @@Error,
			@RowCount = @@Rowcount

		if	@Error != 0 begin
			set	@Result = 999999
			RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			rollback tran @ProcName
			return
		end
		if	@RowCount != @NumberCount begin
			set	@Result = 999999
			RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: %d.', 16, 1, @TableName, @ProcName, @RowCount, @NumberCount)
			rollback tran @ProcName
			return
		end
		--- </Update>

/*			Increment the next delivery number. */

		--- <Update rows="1">
		set	@TableName = 'FT.NumberSequence'

		update
			ns
		set
			NextValue = ns.NextValue + @NumberCount
		from
			FT.NumberSequenceKeys nsk
			join FT.NumberSequence ns with(updlock)
				on ns.NumberSequenceID = nsk.NumberSequenceID
		where
			nsk.KeyName = 'dbo.BackflushHeaders.BackflushNumber'

		select
			@Error = @@Error,
			@RowCount = @@Rowcount

		if	@Error != 0 begin
			set	@Result = 999999
			RAISERROR ('Error updating table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
			rollback tran @ProcName
			return
		end
		if	@RowCount != 1 begin
			set	@Result = 999999
			RAISERROR ('Error updating %s in procedure %s.  Rows Updated: %d.  Expected rows: 1.', 16, 1, @TableName, @ProcName, @RowCount)
			rollback tran @ProcName
			return
		end
		--- </Update>
	end
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
	dbo.BacklushHeaders
...

update
	...
from
	dbo.BacklushHeaders
...

delete
	...
from
	dbo.BacklushHeaders
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
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create trigger [dbo].[trBackflushHeaders_d] on [dbo].[BackflushHeaders] instead of delete
as
/*	Don't allow deletes.  */
update
	bh
set
	Status = dbo.udf_StatusValue('dbo.BackflushHeaders', 'Deleted')
,	RowModifiedDT = getdate()
,	RowModifiedUser = suser_name()
from
	dbo.BackflushHeaders bh
	join deleted d on
		bh.RowID = d.RowID
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[trBackflushHeaders_u] on [dbo].[BackflushHeaders] for update
as
/*	Record modification user and date.  */
if	not update(RowModifiedDT)
	and
		not update(RowModifiedUser) begin
	update
		bh
	set
		RowModifiedDT = getdate()
	,	RowModifiedUser = suser_name()
	from
		dbo.BackflushHeaders bh
		join inserted i on
			bh.RowID = i.RowID
end
GO
ALTER TABLE [dbo].[BackflushHeaders] ADD CONSTRAINT [PK__Backflus__FFEE74516700EA91] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
