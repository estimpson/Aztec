CREATE TABLE [dbo].[PartPackaging_ShipTo]
(
[ShipToCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PartCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PackagingCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__PartPacka__Statu__27BB597B] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__PartPackag__Type__28AF7DB4] DEFAULT ((0)),
[PackDisabled] [tinyint] NULL CONSTRAINT [DF__PartPacka__PackD__29A3A1ED] DEFAULT ((0)),
[PackEnabled] [tinyint] NULL CONSTRAINT [DF__PartPacka__PackE__2A97C626] DEFAULT ((0)),
[PackDefault] [tinyint] NULL CONSTRAINT [DF__PartPacka__PackD__2B8BEA5F] DEFAULT ((0)),
[PackWarn] [tinyint] NULL CONSTRAINT [DF__PartPacka__PackW__2C800E98] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__PartPacka__RowCr__2D7432D1] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__PartPacka__RowCr__2E68570A] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__PartPacka__RowMo__2F5C7B43] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__PartPacka__RowMo__30509F7C] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PartPackaging_ShipTo] ADD CONSTRAINT [PK__PartPack__FFEE74510838D6A9] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PartPackaging_ShipTo] ADD CONSTRAINT [UQ__PartPack__C0B548BD09025FFA] UNIQUE NONCLUSTERED  ([ShipToCode], [PartCode], [PackagingCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PartPackaging_ShipTo] ADD CONSTRAINT [FK__PartPacka__Packa__26C73542] FOREIGN KEY ([PackagingCode]) REFERENCES [dbo].[package_materials] ([code])
GO
ALTER TABLE [dbo].[PartPackaging_ShipTo] ADD CONSTRAINT [FK__PartPacka__PartC__25D31109] FOREIGN KEY ([PartCode]) REFERENCES [dbo].[part] ([part])
GO
ALTER TABLE [dbo].[PartPackaging_ShipTo] ADD CONSTRAINT [FK__PartPacka__ShipT__24DEECD0] FOREIGN KEY ([ShipToCode]) REFERENCES [dbo].[destination] ([destination])
GO
