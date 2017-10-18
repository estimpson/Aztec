CREATE TABLE [FX].[ShipperHeaders]
(
[ShipperNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Type] [int] NOT NULL CONSTRAINT [DF__ShipperHea__Type__65570293] DEFAULT ((0)),
[Status] [int] NOT NULL CONSTRAINT [DF__ShipperHe__Statu__664B26CC] DEFAULT ((0)),
[ShipToCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DepartureDockCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DeparturePlant] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ScheduledShipDT] [datetime] NULL,
[ActualShippedDT] [datetime] NULL,
[Notes] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OperatorCode] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipperHe__LastU__673F4B05] DEFAULT (suser_sname()),
[LastDT] [datetime] NOT NULL CONSTRAINT [DF__ShipperHe__LastD__68336F3E] DEFAULT (getdate()),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowGUID] [uniqueidentifier] NULL ROWGUIDCOL CONSTRAINT [DF__ShipperHe__RowGU__69279377] DEFAULT (newid())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperHeaders] ADD CONSTRAINT [PK__ShipperH__FFEE74515DB5E0CB] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperHeaders] ADD CONSTRAINT [UQ__ShipperH__B174D9DD636EBA21] UNIQUE NONCLUSTERED  ([RowGUID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperHeaders] ADD CONSTRAINT [UQ__ShipperH__ED0F8CBF60924D76] UNIQUE NONCLUSTERED  ([ShipperNumber]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ShipperHeaders_Status] ON [FX].[ShipperHeaders] ([Status], [ScheduledShipDT], [ShipperNumber]) ON [PRIMARY]
GO
