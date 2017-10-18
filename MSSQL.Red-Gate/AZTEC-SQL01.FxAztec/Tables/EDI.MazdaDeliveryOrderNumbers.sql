CREATE TABLE [EDI].[MazdaDeliveryOrderNumbers]
(
[DeliveryOrderNumber] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Quantity] [numeric] (10, 6) NULL,
[OrderNo] [int] NOT NULL,
[ShipperID] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[MazdaDeliveryOrderNumbers] ADD CONSTRAINT [PK__MazdaDel__A8A300D104E65333] PRIMARY KEY CLUSTERED  ([DeliveryOrderNumber], [OrderNo], [ShipperID]) ON [PRIMARY]
GO
