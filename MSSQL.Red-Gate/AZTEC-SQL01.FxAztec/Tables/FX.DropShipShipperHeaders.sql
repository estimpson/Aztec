CREATE TABLE [FX].[DropShipShipperHeaders]
(
[ShipperNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShipperHeaderID] [int] NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__DropShipS__Statu__0E8E2250] DEFAULT ((0)),
[SupplierCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ArrivalDockCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__DropShipS__LastU__0F824689] DEFAULT (suser_sname()),
[LastDT] [datetime] NOT NULL CONSTRAINT [DF__DropShipS__LastD__10766AC2] DEFAULT (getdate()),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowGUID] [uniqueidentifier] NULL ROWGUIDCOL CONSTRAINT [DF__DropShipS__RowGU__116A8EFB] DEFAULT (newid())
) ON [PRIMARY]
GO
ALTER TABLE [FX].[DropShipShipperHeaders] ADD CONSTRAINT [PK__DropShip__FFEE745107E124C1] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[DropShipShipperHeaders] ADD CONSTRAINT [UQ__DropShip__B174D9DD0ABD916C] UNIQUE NONCLUSTERED  ([RowGUID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[DropShipShipperHeaders] ADD CONSTRAINT [FK__DropShipS__Shipp__1D66518C] FOREIGN KEY ([ShipperNumber]) REFERENCES [FX].[ShipperHeaders] ([ShipperNumber])
GO
ALTER TABLE [FX].[DropShipShipperHeaders] ADD CONSTRAINT [FK__DropShipS__Shipp__1E5A75C5] FOREIGN KEY ([ShipperHeaderID]) REFERENCES [FX].[ShipperHeaders] ([RowID])
GO
ALTER TABLE [FX].[DropShipShipperHeaders] ADD CONSTRAINT [FK__DropShipS__Shipp__3EC74557] FOREIGN KEY ([ShipperNumber]) REFERENCES [FX].[ShipperHeaders] ([ShipperNumber])
GO
ALTER TABLE [FX].[DropShipShipperHeaders] ADD CONSTRAINT [FK__DropShipS__Shipp__3FBB6990] FOREIGN KEY ([ShipperHeaderID]) REFERENCES [FX].[ShipperHeaders] ([RowID])
GO
ALTER TABLE [FX].[DropShipShipperHeaders] ADD CONSTRAINT [FK__DropShipS__Shipp__5E74FADA] FOREIGN KEY ([ShipperNumber]) REFERENCES [FX].[ShipperHeaders] ([ShipperNumber])
GO
ALTER TABLE [FX].[DropShipShipperHeaders] ADD CONSTRAINT [FK__DropShipS__Shipp__5F691F13] FOREIGN KEY ([ShipperHeaderID]) REFERENCES [FX].[ShipperHeaders] ([RowID])
GO
ALTER TABLE [FX].[DropShipShipperHeaders] ADD CONSTRAINT [FK__DropShipS__Shipp__7CF981FA] FOREIGN KEY ([ShipperNumber]) REFERENCES [FX].[ShipperHeaders] ([ShipperNumber])
GO
ALTER TABLE [FX].[DropShipShipperHeaders] ADD CONSTRAINT [FK__DropShipS__Shipp__7DEDA633] FOREIGN KEY ([ShipperHeaderID]) REFERENCES [FX].[ShipperHeaders] ([RowID])
GO
