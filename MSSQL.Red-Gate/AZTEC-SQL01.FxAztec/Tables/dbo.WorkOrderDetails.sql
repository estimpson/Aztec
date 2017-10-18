CREATE TABLE [dbo].[WorkOrderDetails]
(
[WorkOrderNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Line] [float] NOT NULL CONSTRAINT [DF__WorkOrderD__Line__670B0C32] DEFAULT ((0)),
[Status] [int] NOT NULL CONSTRAINT [DF__WorkOrder__Statu__67FF306B] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__WorkOrderD__Type__68F354A4] DEFAULT ((0)),
[ProcessCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TopPartCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PartCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Sequence] [int] NULL,
[DueDT] [datetime] NULL,
[QtyRequired] [numeric] (20, 6) NOT NULL,
[QtyLabelled] [numeric] (20, 6) NOT NULL CONSTRAINT [DF__WorkOrder__QtyLa__69E778DD] DEFAULT ((0)),
[QtyCompleted] [numeric] (20, 6) NOT NULL CONSTRAINT [DF__WorkOrder__QtyCo__6ADB9D16] DEFAULT ((0)),
[QtyDefect] [numeric] (20, 6) NOT NULL CONSTRAINT [DF__WorkOrder__QtyDe__6BCFC14F] DEFAULT ((0)),
[QtyRework] [numeric] (20, 6) NOT NULL CONSTRAINT [DF__WorkOrder__QtyRe__6CC3E588] DEFAULT ((0)),
[SetupHours] [numeric] (20, 6) NOT NULL CONSTRAINT [DF__WorkOrder__Setup__6DB809C1] DEFAULT ((0)),
[PartsPerHour] [numeric] (20, 6) NOT NULL,
[PartsPerCycle] [numeric] (20, 6) NOT NULL CONSTRAINT [DF__WorkOrder__Parts__6EAC2DFA] DEFAULT ((1)),
[CycleSeconds] [numeric] (20, 6) NOT NULL,
[StartDT] [datetime] NULL,
[EndDT] [datetime] NULL,
[ShipperID] [int] NULL,
[SalesOrderNumber] [int] NULL,
[DestinationCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Notes] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__WorkOrder__RowCr__6FA05233] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__WorkOrder__RowCr__7094766C] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__WorkOrder__RowMo__71889AA5] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__WorkOrder__RowMo__727CBEDE] DEFAULT (suser_name())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create trigger [dbo].[trWorkOrderDetails_d] on [dbo].[WorkOrderDetails] instead of delete
as
/*	Don't allow deletes.  */
update
	dbo.WorkOrderDetails
set
	Status = dbo.udf_StatusValue('dbo.WorkOrderDetails', 'Deleted')
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

create trigger [dbo].[trWorkOrderDetails_u] on [dbo].[WorkOrderDetails] for update
as
/*	Record modification user and date.  */
if	not update(RowModifiedDT)
	and
		not update(RowModifiedUser) begin
	update
		dbo.WorkOrderDetails
	set
		RowModifiedDT = getdate()
	,	RowModifiedUser = suser_name()
	from
		dbo.WorkOrderDetails wod
		join inserted i on
			wod.RowID = i.RowID
end
GO
ALTER TABLE [dbo].[WorkOrderDetails] ADD CONSTRAINT [PK__WorkOrde__FFEE7451615232DC] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[WorkOrderDetails] ADD CONSTRAINT [UQ__WorkOrde__64263250642E9F87] UNIQUE NONCLUSTERED  ([WorkOrderNumber], [Line]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[WorkOrderDetails] ADD CONSTRAINT [FK__WorkOrder__WorkO__6616E7F9] FOREIGN KEY ([WorkOrderNumber]) REFERENCES [dbo].[WorkOrderHeaders] ([WorkOrderNumber])
GO
