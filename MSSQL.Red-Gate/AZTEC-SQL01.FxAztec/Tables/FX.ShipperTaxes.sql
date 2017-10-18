CREATE TABLE [FX].[ShipperTaxes]
(
[ShipperNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShipperHeaderID] [int] NOT NULL,
[Type] [int] NOT NULL CONSTRAINT [DF__ShipperTax__Type__1CA7377D] DEFAULT ((0)),
[Status] [int] NOT NULL CONSTRAINT [DF__ShipperTa__Statu__1D9B5BB6] DEFAULT ((0)),
[TaxRate] [numeric] (20, 6) NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipperTa__LastU__1E8F7FEF] DEFAULT (suser_sname()),
[LastDT] [datetime] NOT NULL CONSTRAINT [DF__ShipperTa__LastD__1F83A428] DEFAULT (getdate()),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowGUID] [uniqueidentifier] NULL ROWGUIDCOL CONSTRAINT [DF__ShipperTa__RowGU__2077C861] DEFAULT (newid())
) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperTaxes] ADD CONSTRAINT [PK__ShipperT__FFEE745115FA39EE] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperTaxes] ADD CONSTRAINT [UQ__ShipperT__B174D9DD18D6A699] UNIQUE NONCLUSTERED  ([RowGUID]) ON [PRIMARY]
GO
