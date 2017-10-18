CREATE TABLE [FX].[ShipperDocuments]
(
[ShipperNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShipperHeaderID] [int] NOT NULL,
[Type] [int] NOT NULL CONSTRAINT [DF__ShipperDoc__Type__5708E33C] DEFAULT ((0)),
[Status] [int] NOT NULL CONSTRAINT [DF__ShipperDo__Statu__57FD0775] DEFAULT ((0)),
[DocumentName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipperDo__LastU__58F12BAE] DEFAULT (suser_sname()),
[LastDT] [datetime] NOT NULL CONSTRAINT [DF__ShipperDo__LastD__59E54FE7] DEFAULT (getdate()),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowGUID] [uniqueidentifier] NULL ROWGUIDCOL CONSTRAINT [DF__ShipperDo__RowGU__5AD97420] DEFAULT (newid())
) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperDocuments] ADD CONSTRAINT [PK__ShipperD__FFEE7451505BE5AD] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperDocuments] ADD CONSTRAINT [UQ__ShipperD__B174D9DD53385258] UNIQUE NONCLUSTERED  ([RowGUID]) ON [PRIMARY]
GO
