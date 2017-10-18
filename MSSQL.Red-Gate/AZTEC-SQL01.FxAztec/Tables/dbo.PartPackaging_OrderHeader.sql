CREATE TABLE [dbo].[PartPackaging_OrderHeader]
(
[OrderNo] [numeric] (8, 0) NULL,
[PartCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PackagingCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__PartPacka__Statu__36FD9D0B] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__PartPackag__Type__37F1C144] DEFAULT ((0)),
[PackDisabled] [tinyint] NULL CONSTRAINT [DF__PartPacka__PackD__38E5E57D] DEFAULT ((0)),
[PackEnabled] [tinyint] NULL CONSTRAINT [DF__PartPacka__PackE__39DA09B6] DEFAULT ((0)),
[PackDefault] [tinyint] NULL CONSTRAINT [DF__PartPacka__PackD__3ACE2DEF] DEFAULT ((0)),
[PackWarn] [tinyint] NULL CONSTRAINT [DF__PartPacka__PackW__3BC25228] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__PartPacka__RowCr__3CB67661] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__PartPacka__RowCr__3DAA9A9A] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__PartPacka__RowMo__3E9EBED3] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__PartPacka__RowMo__3F92E30C] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PartPackaging_OrderHeader] ADD CONSTRAINT [PK__PartPack__FFEE74514E450F75] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PartPackaging_OrderHeader] ADD CONSTRAINT [UQ__PartPack__297269C3D35F6D76] UNIQUE NONCLUSTERED  ([OrderNo], [PartCode], [PackagingCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PartPackaging_OrderHeader] ADD CONSTRAINT [FK__PartPacka__Order__34213060] FOREIGN KEY ([OrderNo]) REFERENCES [dbo].[order_header] ([order_no])
GO
ALTER TABLE [dbo].[PartPackaging_OrderHeader] ADD CONSTRAINT [FK__PartPacka__Packa__360978D2] FOREIGN KEY ([PackagingCode]) REFERENCES [dbo].[package_materials] ([code])
GO
ALTER TABLE [dbo].[PartPackaging_OrderHeader] ADD CONSTRAINT [FK__PartPacka__PartC__35155499] FOREIGN KEY ([PartCode]) REFERENCES [dbo].[part] ([part])
GO
