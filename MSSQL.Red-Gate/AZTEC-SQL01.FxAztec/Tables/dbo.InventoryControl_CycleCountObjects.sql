CREATE TABLE [dbo].[InventoryControl_CycleCountObjects]
(
[CycleCountNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Line] [float] NULL,
[Serial] [int] NULL,
[ParentSerial] [int] NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__Inventory__Statu__0F3C2679] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__InventoryC__Type__10304AB2] DEFAULT ((0)),
[Part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OriginalQuantity] [numeric] (20, 6) NOT NULL,
[CorrectedQuantity] [numeric] (20, 6) NULL,
[Unit] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OriginalLocation] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CorrectedLocation] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowCommittedDT] [datetime] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Inventory__RowCr__11246EEB] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Inventory__RowCr__12189324] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Inventory__RowMo__130CB75D] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Inventory__RowMo__1400DB96] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[InventoryControl_CycleCountObjects] ADD CONSTRAINT [PK__Inventor__FFEE745003F3CF9E] PRIMARY KEY NONCLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[InventoryControl_CycleCountObjects] ADD CONSTRAINT [UQ__Inventor__530AB6685EDCCA23] UNIQUE CLUSTERED  ([CycleCountNumber], [Line]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[InventoryControl_CycleCountObjects] ADD CONSTRAINT [UQ__Inventor__1928C5A66210D6F3] UNIQUE NONCLUSTERED  ([CycleCountNumber], [Serial], [RowCommittedDT]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[InventoryControl_CycleCountObjects] ADD CONSTRAINT [FK__Inventory__Cycle__0E480240] FOREIGN KEY ([CycleCountNumber]) REFERENCES [dbo].[InventoryControl_CycleCountHeaders] ([CycleCountNumber])
GO
