CREATE TABLE [dbo].[WorkOrderObjects]
(
[Serial] [int] NULL,
[WorkOrderNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[WorkOrderDetailLine] [float] NOT NULL CONSTRAINT [DF__WorkOrder__WorkO__0D7B9934] DEFAULT ((0)),
[Status] [int] NOT NULL CONSTRAINT [DF__WorkOrder__Statu__0E6FBD6D] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__WorkOrderO__Type__0F63E1A6] DEFAULT ((0)),
[PartCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PackageType] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OperatorCode] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Quantity] [numeric] (20, 6) NOT NULL,
[LotNumber] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CompletionDT] [datetime] NULL,
[BackflushNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UndoBackflushNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__WorkOrder__RowCr__12404E51] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__WorkOrder__RowCr__1334728A] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__WorkOrder__RowMo__142896C3] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__WorkOrder__RowMo__151CBAFC] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[WorkOrderObjects] ADD CONSTRAINT [PK__WorkOrde__FFEE745108B6E417] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[WorkOrderObjects] ADD CONSTRAINT [UQ__WorkOrde__1A00E0930B9350C2] UNIQUE NONCLUSTERED  ([Serial]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[WorkOrderObjects] ADD CONSTRAINT [FK__WorkOrder__Backf__105805DF] FOREIGN KEY ([BackflushNumber]) REFERENCES [dbo].[BackflushHeaders] ([BackflushNumber])
GO
ALTER TABLE [dbo].[WorkOrderObjects] ADD CONSTRAINT [FK__WorkOrder__UndoB__114C2A18] FOREIGN KEY ([UndoBackflushNumber]) REFERENCES [dbo].[BackflushHeaders] ([BackflushNumber])
GO
ALTER TABLE [dbo].[WorkOrderObjects] ADD CONSTRAINT [FK__WorkOrderObjects__23C3D8C1] FOREIGN KEY ([WorkOrderNumber], [WorkOrderDetailLine]) REFERENCES [dbo].[WorkOrderDetails] ([WorkOrderNumber], [Line])
GO
