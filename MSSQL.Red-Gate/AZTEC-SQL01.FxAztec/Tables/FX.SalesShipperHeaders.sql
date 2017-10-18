CREATE TABLE [FX].[SalesShipperHeaders]
(
[ShipperNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShipperHeaderID] [int] NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__SalesShip__Statu__31D75E8D] DEFAULT ((0)),
[BillToCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ArrivalDockCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RequiredDepartureDT] [datetime] NULL,
[RequiredArrivalDT] [datetime] NULL,
[PaymentTermsCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[InvoiceCurrencyUnit] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__SalesShip__LastU__32CB82C6] DEFAULT (suser_sname()),
[LastDT] [datetime] NOT NULL CONSTRAINT [DF__SalesShip__LastD__33BFA6FF] DEFAULT (getdate()),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowGUID] [uniqueidentifier] NULL ROWGUIDCOL CONSTRAINT [DF__SalesShip__RowGU__34B3CB38] DEFAULT (newid())
) ON [PRIMARY]
GO
ALTER TABLE [FX].[SalesShipperHeaders] ADD CONSTRAINT [PK__SalesShi__FFEE74512B2A60FE] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[SalesShipperHeaders] ADD CONSTRAINT [UQ__SalesShi__B174D9DD2E06CDA9] UNIQUE NONCLUSTERED  ([RowGUID]) ON [PRIMARY]
GO
