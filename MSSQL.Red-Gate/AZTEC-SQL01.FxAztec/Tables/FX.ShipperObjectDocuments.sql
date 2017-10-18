CREATE TABLE [FX].[ShipperObjectDocuments]
(
[ShipperNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShipperHeaderID] [int] NOT NULL,
[ShipperObjectID] [int] NOT NULL,
[Type] [int] NOT NULL CONSTRAINT [DF__ShipperObj__Type__73A521EA] DEFAULT ((0)),
[Status] [int] NOT NULL CONSTRAINT [DF__ShipperOb__Statu__74994623] DEFAULT ((0)),
[DocumentName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipperOb__LastU__758D6A5C] DEFAULT (suser_sname()),
[LastDT] [datetime] NOT NULL CONSTRAINT [DF__ShipperOb__LastD__76818E95] DEFAULT (getdate()),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowGUID] [uniqueidentifier] NULL ROWGUIDCOL CONSTRAINT [DF__ShipperOb__RowGU__7775B2CE] DEFAULT (newid())
) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperObjectDocuments] ADD CONSTRAINT [PK__ShipperO__FFEE74516C040022] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperObjectDocuments] ADD CONSTRAINT [UQ__ShipperO__B174D9DD6EE06CCD] UNIQUE NONCLUSTERED  ([RowGUID]) ON [PRIMARY]
GO
