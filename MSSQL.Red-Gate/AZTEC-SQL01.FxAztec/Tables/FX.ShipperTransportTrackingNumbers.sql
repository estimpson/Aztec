CREATE TABLE [FX].[ShipperTransportTrackingNumbers]
(
[ShipperNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShipperHeaderID] [int] NOT NULL,
[Sequence] [int] NOT NULL,
[Type] [int] NOT NULL CONSTRAINT [DF__ShipperTra__Type__3B2BBE9D] DEFAULT ((0)),
[Value] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipperTr__LastU__3C1FE2D6] DEFAULT (suser_sname()),
[LastDT] [datetime] NOT NULL CONSTRAINT [DF__ShipperTr__LastD__3D14070F] DEFAULT (getdate()),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowGUID] [uniqueidentifier] NULL ROWGUIDCOL CONSTRAINT [DF__ShipperTr__RowGU__3E082B48] DEFAULT (newid())
) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperTransportTrackingNumbers] ADD CONSTRAINT [PK__ShipperT__FFEE7451338A9CD5] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperTransportTrackingNumbers] ADD CONSTRAINT [UQ__ShipperT__B174D9DD36670980] UNIQUE NONCLUSTERED  ([RowGUID]) ON [PRIMARY]
GO
