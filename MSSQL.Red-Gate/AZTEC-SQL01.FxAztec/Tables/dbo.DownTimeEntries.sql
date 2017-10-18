CREATE TABLE [dbo].[DownTimeEntries]
(
[Status] [int] NOT NULL CONSTRAINT [DF__DownTimeE__Statu__40E5634A] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__DownTimeEn__Type__41D98783] DEFAULT ((0)),
[Machine] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DownTimeCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DownTimeHours] [numeric] (20, 6) NULL,
[Notes] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Operator] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShiftDT] [datetime] NULL,
[WorkOrderNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WorkOrderDetailSequence] [int] NULL,
[BeginDownTimeDT] [datetime] NULL,
[EndDownTimeDT] [datetime] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__DownTimeE__RowCr__43C1CFF5] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__DownTimeE__RowCr__44B5F42E] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__DownTimeE__RowMo__45AA1867] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__DownTimeE__RowMo__469E3CA0] DEFAULT (suser_name())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[trDownTimeEntries_d] on [dbo].[DownTimeEntries] instead of delete
as
/*	Don't allow deletes.  */
update
	dte
set
	Status = dbo.udf_StatusValue('dbo.DownTimeEntries', 'Deleted')
,	RowModifiedDT = getdate()
,	RowModifiedUser = suser_name()
from
	dbo.DownTimeEntries dte
	join deleted d on
		dte.RowID = d.RowID
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create trigger [dbo].[trDownTimeEntries_u] on [dbo].[DownTimeEntries] for update
as
/*	Record modification user and date.  */
if	not update(RowModifiedDT)
	and
		not update(RowModifiedUser) begin
	update
		dte
	set
		RowModifiedDT = getdate()
	,	RowModifiedUser = suser_name()
	from
		dbo.DownTimeEntries dte
		join inserted i on
			dte.RowID = i.RowID
end
GO
ALTER TABLE [dbo].[DownTimeEntries] ADD CONSTRAINT [PK__DownTime__FFEE74513EFD1AD8] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DownTimeEntries] ADD CONSTRAINT [FK__DownTimeE__WorkO__42CDABBC] FOREIGN KEY ([WorkOrderNumber]) REFERENCES [dbo].[WorkOrderHeaders] ([WorkOrderNumber])
GO
