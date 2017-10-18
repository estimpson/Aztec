CREATE TABLE [dbo].[WorkOrderHeaders]
(
[WorkOrderNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__WorkOrder__WorkO__4D804459] DEFAULT ((0)),
[Status] [int] NOT NULL CONSTRAINT [DF__WorkOrder__Statu__4E746892] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__WorkOrderH__Type__4F688CCB] DEFAULT ((0)),
[MachineCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ToolCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Sequence] [int] NULL,
[DueDT] [datetime] NULL,
[ScheduledSetupHours] [numeric] (20, 6) NOT NULL CONSTRAINT [DF__WorkOrder__Sched__505CB104] DEFAULT ((0)),
[ScheduledStartDT] [datetime] NULL,
[ScheduledEndDT] [datetime] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__WorkOrder__RowCr__5150D53D] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__WorkOrder__RowCr__5244F976] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__WorkOrder__RowMo__53391DAF] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__WorkOrder__RowMo__542D41E8] DEFAULT (suser_name())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create trigger [dbo].[trWorkOrderHeaders_d] on [dbo].[WorkOrderHeaders] instead of delete
as
/*	Don't allow deletes.  */
update
	woh
set
	Status = dbo.udf_StatusValue('dbo.WorkOrderHeaders', 'Deleted')
,	RowModifiedDT = getdate()
,	RowModifiedUser = suser_name()
from
	dbo.WorkOrderHeaders woh
	join deleted d on
		woh.RowID = d.RowID
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[trWorkOrderHeaders_i] on [dbo].[WorkOrderHeaders] for insert
as
set nocount on
set ansi_warnings off
declare
	@Result int

--- <Error Handling>
declare
	@CallProcName sysname,
	@TableName sysname,
	@ProcName sysname,
	@ProcReturn integer,
	@ProcResult integer,
	@Error integer,
	@RowCount integer

set	@ProcName = user_name(objectproperty(@@procid, 'OwnerId')) + '.' + object_name(@@procid)  -- e.g. FT.usp_Test
--- </Error Handling>

--- <Tran Required=No AutoCreate=No TranDTParm=No>
declare
	@TranDT datetime
set	@TranDT = coalesce(@TranDT, GetDate())
--- </Tran>

--- <Body>
declare
	@NextNumber varchar(50)

--- <Call>	
set	@CallProcName = 'FT.usp_NextNumberInSequnce'
execute
	@ProcReturn = FT.usp_NextNumberInSequnce
	@KeyName = 'dbo.WorkOrderHeaders.WorkOrderNumber'
,	@NextNumber = @NextNumber out
,	@TranDT = @TranDT out
,	@Result = @ProcResult out

set	@Error = @@Error
if	@Error != 0 begin
	set	@Result = 900501
	RAISERROR ('Error encountered in %s.  Error: %d while calling %s', 16, 1, @ProcName, @Error, @CallProcName)
	rollback tran
	return
end
if	@ProcReturn != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcReturn: %d while calling %s', 16, 1, @ProcName, @ProcReturn, @CallProcName)
	rollback tran
	return
end
if	@ProcResult != 0 begin
	set	@Result = 900502
	RAISERROR ('Error encountered in %s.  ProcResult: %d while calling %s', 16, 1, @ProcName, @ProcResult, @CallProcName)
	rollback tran
	return
end
--- </Call>

--- <Update rows="*">
set	@TableName = 'dbo.WorkOrderHeaders'

update
	woh
set
	WorkOrderNumber = @NextNumber
from
	dbo.WorkOrderHeaders woh
	join inserted i on
		woh.RowID = i.RowID
where
	i.WorkOrderNumber = '0'

select
	@Error = @@Error,
	@RowCount = @@Rowcount

if	@Error != 0 begin
	set	@Result = 999999
	RAISERROR ('Error inserting table %s in procedure %s.  Error: %d', 16, 1, @TableName, @ProcName, @Error)
	rollback tran
	return
end
--- </Update>
--- </Body>
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[trWorkOrderHeaders_u] on [dbo].[WorkOrderHeaders] for update
as
/*	Record modification user and date.  */
if	not update(RowModifiedDT)
	and
		not update(RowModifiedUser) begin
	update
		woh
	set
		RowModifiedDT = getdate()
	,	RowModifiedUser = suser_name()
	from
		dbo.WorkOrderHeaders woh
		join inserted i on
			woh.RowID = i.RowID
end
GO
ALTER TABLE [dbo].[WorkOrderHeaders] ADD CONSTRAINT [PK__WorkOrde__FFEE745148BB8F3C] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[WorkOrderHeaders] ADD CONSTRAINT [UQ__WorkOrde__1FA44F964B97FBE7] UNIQUE NONCLUSTERED  ([WorkOrderNumber]) ON [PRIMARY]
GO
