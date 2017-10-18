CREATE TABLE [dbo].[PartPackaging_BillTo]
(
[BillToCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PartCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PackagingCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__PartPacka__Statu__187915EB] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__PartPackag__Type__196D3A24] DEFAULT ((0)),
[PackDisabled] [tinyint] NULL CONSTRAINT [DF__PartPacka__PackD__1A615E5D] DEFAULT ((0)),
[PackEnabled] [tinyint] NULL CONSTRAINT [DF__PartPacka__PackE__1B558296] DEFAULT ((0)),
[PackDefault] [tinyint] NULL CONSTRAINT [DF__PartPacka__PackD__1C49A6CF] DEFAULT ((0)),
[PackWarn] [tinyint] NULL CONSTRAINT [DF__PartPacka__PackW__1D3DCB08] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__PartPacka__RowCr__1E31EF41] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__PartPacka__RowCr__1F26137A] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__PartPacka__RowMo__201A37B3] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__PartPacka__RowMo__210E5BEC] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PartPackaging_BillTo] ADD CONSTRAINT [PK__PartPack__FFEE7451EE332101] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PartPackaging_BillTo] ADD CONSTRAINT [UQ__PartPack__811C3FAF169B0031] UNIQUE NONCLUSTERED  ([BillToCode], [PartCode], [PackagingCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PartPackaging_BillTo] ADD CONSTRAINT [FK__PartPacka__BillT__159CA940] FOREIGN KEY ([BillToCode]) REFERENCES [dbo].[customer] ([customer])
GO
ALTER TABLE [dbo].[PartPackaging_BillTo] ADD CONSTRAINT [FK__PartPacka__Packa__1784F1B2] FOREIGN KEY ([PackagingCode]) REFERENCES [dbo].[package_materials] ([code])
GO
ALTER TABLE [dbo].[PartPackaging_BillTo] ADD CONSTRAINT [FK__PartPacka__PartC__1690CD79] FOREIGN KEY ([PartCode]) REFERENCES [dbo].[part] ([part])
GO
