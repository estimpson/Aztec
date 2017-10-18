CREATE TABLE [FX].[ShipperObjects]
(
[ShipperNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShipperHeaderID] [int] NOT NULL,
[LineNo] [float] NOT NULL CONSTRAINT [DF__ShipperOb__LineN__00FF1D08] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__ShipperObj__Type__01F34141] DEFAULT ((0)),
[Status] [int] NOT NULL CONSTRAINT [DF__ShipperOb__Statu__02E7657A] DEFAULT ((0)),
[Serial] [int] NULL,
[PartCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PartDescription] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EngineeringLevel] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QtyObject] [numeric] (20, 6) NULL,
[PackageType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Plant] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ParentSerial] [int] NULL,
[DrAccount] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CrAccount] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NetWeight] [numeric] (20, 6) NULL,
[TareWeight] [numeric] (20, 6) NULL,
[GrossWeight] [numeric] (20, 6) NULL,
[Lot] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Note] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserDefinedStatus] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipperOb__LastU__03DB89B3] DEFAULT (suser_sname()),
[LastDT] [datetime] NOT NULL CONSTRAINT [DF__ShipperOb__LastD__04CFADEC] DEFAULT (getdate()),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowGUID] [uniqueidentifier] NULL ROWGUIDCOL CONSTRAINT [DF__ShipperOb__RowGU__05C3D225] DEFAULT (newid())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperObjects] ADD CONSTRAINT [PK__ShipperO__FFEE74517A521F79] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperObjects] ADD CONSTRAINT [UQ__ShipperO__B174D9DD7D2E8C24] UNIQUE NONCLUSTERED  ([RowGUID]) ON [PRIMARY]
GO
