CREATE TABLE [FX].[ShipperObjectTaxes]
(
[ShipperNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShipperHeaderID] [int] NOT NULL,
[ShipperObjectID] [int] NOT NULL,
[TaxGUID] [uniqueidentifier] NOT NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipperOb__LastU__113584D1] DEFAULT (suser_sname()),
[LastDT] [datetime] NOT NULL CONSTRAINT [DF__ShipperOb__LastD__1229A90A] DEFAULT (getdate()),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowGUID] [uniqueidentifier] NULL ROWGUIDCOL CONSTRAINT [DF__ShipperOb__RowGU__131DCD43] DEFAULT (newid())
) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperObjectTaxes] ADD CONSTRAINT [PK__ShipperO__FFEE745108A03ED0] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperObjectTaxes] ADD CONSTRAINT [UQ__ShipperO__B174D9DD0B7CAB7B] UNIQUE NONCLUSTERED  ([RowGUID]) ON [PRIMARY]
GO
