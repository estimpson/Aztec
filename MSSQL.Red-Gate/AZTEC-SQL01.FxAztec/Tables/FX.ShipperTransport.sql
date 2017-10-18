CREATE TABLE [FX].[ShipperTransport]
(
[ShipperNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShipperHeaderID] [int] NOT NULL,
[Type] [int] NOT NULL CONSTRAINT [DF__ShipperTra__Type__2CDD9F46] DEFAULT ((0)),
[Status] [int] NOT NULL CONSTRAINT [DF__ShipperTr__Statu__2DD1C37F] DEFAULT ((0)),
[Sequence] [int] NULL,
[CarrierCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TransportationMode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FreightCode] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FreightAmount] [numeric] (20, 6) NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipperTr__LastU__2EC5E7B8] DEFAULT (suser_sname()),
[LastDT] [datetime] NOT NULL CONSTRAINT [DF__ShipperTr__LastD__2FBA0BF1] DEFAULT (getdate()),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowGUID] [uniqueidentifier] NULL ROWGUIDCOL CONSTRAINT [DF__ShipperTr__RowGU__30AE302A] DEFAULT (newid())
) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperTransport] ADD CONSTRAINT [PK__ShipperT__FFEE74512354350C] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperTransport] ADD CONSTRAINT [UQ__ShipperT__B174D9DD290D0E62] UNIQUE NONCLUSTERED  ([RowGUID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperTransport] ADD CONSTRAINT [UQ__ShipperT__E058D7542630A1B7] UNIQUE NONCLUSTERED  ([ShipperNumber], [Sequence]) ON [PRIMARY]
GO
