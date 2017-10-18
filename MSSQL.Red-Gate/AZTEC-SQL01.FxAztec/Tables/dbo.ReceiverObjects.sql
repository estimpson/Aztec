CREATE TABLE [dbo].[ReceiverObjects]
(
[ReceiverObjectID] [int] NOT NULL IDENTITY(1, 1),
[ReceiverLineID] [int] NOT NULL,
[LineNo] [float] NOT NULL CONSTRAINT [DF__ReceiverO__LineN__09003183] DEFAULT ((0)),
[Status] [bigint] NOT NULL CONSTRAINT [DF__ReceiverO__Statu__09F455BC] DEFAULT ((0)),
[PONumber] [int] NULL,
[POLineNo] [int] NULL,
[POLineDueDate] [datetime] NULL,
[Serial] [int] NULL,
[PartCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PartDescription] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EngineeringLevel] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QtyObject] [numeric] (20, 6) NOT NULL,
[PackageType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Plant] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ParentSerial] [int] NULL,
[DrAccount] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CrAccount] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Lot] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Note] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserDefinedStatus] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReceiveDT] [datetime] NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ReceiverO__LastU__0AE879F5] DEFAULT (suser_sname()),
[LastDT] [datetime] NULL CONSTRAINT [DF__ReceiverO__LastD__0BDC9E2E] DEFAULT (getdate()),
[ParentLicensePlate] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SupplierLicensePlate] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[ReceiverObjects] ADD CONSTRAINT [PK__Receiver__CD4E3EFD0347582D] PRIMARY KEY CLUSTERED  ([ReceiverObjectID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ReceiverObjects_2] ON [dbo].[ReceiverObjects] ([ReceiverLineID]) INCLUDE ([QtyObject], [Status]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ReceiverObjects] ADD CONSTRAINT [UQ__Receiver__6A303F350623C4D8] UNIQUE NONCLUSTERED  ([ReceiverLineID], [LineNo]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ReceiverObject_1] ON [dbo].[ReceiverObjects] ([ReceiverLineID], [PartCode], [Status], [ReceiverObjectID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ReceiverObjects] ADD CONSTRAINT [FK__ReceiverO__Recei__080C0D4A] FOREIGN KEY ([ReceiverLineID]) REFERENCES [dbo].[ReceiverLines] ([ReceiverLineID])
GO
