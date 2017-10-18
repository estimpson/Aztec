CREATE TABLE [FX].[ShipperAddresses]
(
[ShipperNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShipperHeaderID] [int] NOT NULL,
[Type] [int] NOT NULL CONSTRAINT [DF__ShipperAdd__Type__3E3D3572] DEFAULT ((0)),
[Sequence] [int] NULL,
[AddressLine1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AddressLine2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AddressLine3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AddressLine4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AddressLine5] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AddressLine6] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipperAd__LastU__3F3159AB] DEFAULT (suser_sname()),
[LastDT] [datetime] NOT NULL CONSTRAINT [DF__ShipperAd__LastD__40257DE4] DEFAULT (getdate()),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowGUID] [uniqueidentifier] NULL ROWGUIDCOL CONSTRAINT [DF__ShipperAd__RowGU__4119A21D] DEFAULT (newid())
) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperAddresses] ADD CONSTRAINT [PK__ShipperA__FFEE7451379037E3] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperAddresses] ADD CONSTRAINT [UQ__ShipperA__B174D9DD3A6CA48E] UNIQUE NONCLUSTERED  ([RowGUID]) ON [PRIMARY]
GO
