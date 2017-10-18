CREATE TABLE [FX].[OutsideProcessShipperHeaders]
(
[ShipperNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShipperHeaderID] [int] NOT NULL,
[SupplierCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ArrivalDockCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__OutsidePr__LastU__1AF3F935] DEFAULT (suser_sname()),
[LastDT] [datetime] NOT NULL CONSTRAINT [DF__OutsidePr__LastD__1BE81D6E] DEFAULT (getdate()),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowGUID] [uniqueidentifier] NULL ROWGUIDCOL CONSTRAINT [DF__OutsidePr__RowGU__1CDC41A7] DEFAULT (newid())
) ON [PRIMARY]
GO
ALTER TABLE [FX].[OutsideProcessShipperHeaders] ADD CONSTRAINT [PK__OutsideP__FFEE74511446FBA6] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[OutsideProcessShipperHeaders] ADD CONSTRAINT [UQ__OutsideP__B174D9DD17236851] UNIQUE NONCLUSTERED  ([RowGUID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[OutsideProcessShipperHeaders] ADD CONSTRAINT [FK__OutsidePr__Shipp__1F4E99FE] FOREIGN KEY ([ShipperNumber]) REFERENCES [FX].[ShipperHeaders] ([ShipperNumber])
GO
ALTER TABLE [FX].[OutsideProcessShipperHeaders] ADD CONSTRAINT [FK__OutsidePr__Shipp__2042BE37] FOREIGN KEY ([ShipperHeaderID]) REFERENCES [FX].[ShipperHeaders] ([RowID])
GO
ALTER TABLE [FX].[OutsideProcessShipperHeaders] ADD CONSTRAINT [FK__OutsidePr__Shipp__40AF8DC9] FOREIGN KEY ([ShipperNumber]) REFERENCES [FX].[ShipperHeaders] ([ShipperNumber])
GO
ALTER TABLE [FX].[OutsideProcessShipperHeaders] ADD CONSTRAINT [FK__OutsidePr__Shipp__41A3B202] FOREIGN KEY ([ShipperHeaderID]) REFERENCES [FX].[ShipperHeaders] ([RowID])
GO
ALTER TABLE [FX].[OutsideProcessShipperHeaders] ADD CONSTRAINT [FK__OutsidePr__Shipp__605D434C] FOREIGN KEY ([ShipperNumber]) REFERENCES [FX].[ShipperHeaders] ([ShipperNumber])
GO
ALTER TABLE [FX].[OutsideProcessShipperHeaders] ADD CONSTRAINT [FK__OutsidePr__Shipp__61516785] FOREIGN KEY ([ShipperHeaderID]) REFERENCES [FX].[ShipperHeaders] ([RowID])
GO
ALTER TABLE [FX].[OutsideProcessShipperHeaders] ADD CONSTRAINT [FK__OutsidePr__Shipp__7EE1CA6C] FOREIGN KEY ([ShipperNumber]) REFERENCES [FX].[ShipperHeaders] ([ShipperNumber])
GO
ALTER TABLE [FX].[OutsideProcessShipperHeaders] ADD CONSTRAINT [FK__OutsidePr__Shipp__7FD5EEA5] FOREIGN KEY ([ShipperHeaderID]) REFERENCES [FX].[ShipperHeaders] ([RowID])
GO
