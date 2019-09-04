CREATE TABLE [EDI].[ShipToDimensions]
(
[ShipToAddress] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BillToCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BillToName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EDIOperatorCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EDIOverlayGroup] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ParentShipTo] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PoolCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PoolFlag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TradingPartnerCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SupplierCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
