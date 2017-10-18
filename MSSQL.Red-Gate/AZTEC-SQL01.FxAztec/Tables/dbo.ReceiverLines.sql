CREATE TABLE [dbo].[ReceiverLines]
(
[ReceiverLineID] [int] NOT NULL IDENTITY(1, 1),
[ReceiverID] [int] NOT NULL,
[LineNo] [float] NOT NULL CONSTRAINT [DF__ReceiverL__LineN__13BCEBC1] DEFAULT ((0)),
[Status] [bigint] NOT NULL CONSTRAINT [DF__ReceiverL__Statu__14B10FFA] DEFAULT ((0)),
[PartCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PONumber] [int] NOT NULL,
[POLineNo] [int] NULL,
[POLineDueDate] [datetime] NULL,
[PackageType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RemainingBoxes] [int] NULL,
[StdPackQty] [numeric] (20, 6) NOT NULL,
[SupplierLotNumber] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ArrivalDT] [datetime] NULL,
[ReceiptDT] [datetime] NULL,
[PutawayDT] [datetime] NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ReceiverL__LastU__15A53433] DEFAULT (suser_sname()),
[LastDT] [datetime] NULL CONSTRAINT [DF__ReceiverL__LastD__1699586C] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ReceiverLines] ADD CONSTRAINT [PK__Receiver__18DAC4F10E04126B] PRIMARY KEY CLUSTERED  ([ReceiverLineID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ReceiverLines] ADD CONSTRAINT [UQ__Receiver__8C51A4C310E07F16] UNIQUE NONCLUSTERED  ([ReceiverID], [LineNo]) ON [PRIMARY]
GO
