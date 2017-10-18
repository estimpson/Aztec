CREATE TABLE [FX].[ReturnShipperHeaders]
(
[ShipperNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShipperHeaderID] [int] NOT NULL,
[SupplierCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ArrivalDockCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ReturnShi__LastU__2665ABE1] DEFAULT (suser_sname()),
[LastDT] [datetime] NOT NULL CONSTRAINT [DF__ReturnShi__LastD__2759D01A] DEFAULT (getdate()),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowGUID] [uniqueidentifier] NULL ROWGUIDCOL CONSTRAINT [DF__ReturnShi__RowGU__284DF453] DEFAULT (newid())
) ON [PRIMARY]
GO
ALTER TABLE [FX].[ReturnShipperHeaders] ADD CONSTRAINT [PK__ReturnSh__FFEE74511FB8AE52] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[ReturnShipperHeaders] ADD CONSTRAINT [UQ__ReturnSh__B174D9DD22951AFD] UNIQUE NONCLUSTERED  ([RowGUID]) ON [PRIMARY]
GO
