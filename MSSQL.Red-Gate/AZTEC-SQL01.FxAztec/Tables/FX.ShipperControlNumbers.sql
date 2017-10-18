CREATE TABLE [FX].[ShipperControlNumbers]
(
[ShipperNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShipperHeaderID] [int] NOT NULL,
[Type] [int] NOT NULL CONSTRAINT [DF__ShipperCon__Type__4AA30C57] DEFAULT ((0)),
[Value] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipperCo__LastU__4B973090] DEFAULT (suser_sname()),
[LastDT] [datetime] NOT NULL CONSTRAINT [DF__ShipperCo__LastD__4C8B54C9] DEFAULT (getdate()),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowGUID] [uniqueidentifier] NULL ROWGUIDCOL CONSTRAINT [DF__ShipperCo__RowGU__4D7F7902] DEFAULT (newid())
) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperControlNumbers] ADD CONSTRAINT [PK__ShipperC__FFEE745143F60EC8] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FX].[ShipperControlNumbers] ADD CONSTRAINT [UQ__ShipperC__B174D9DD46D27B73] UNIQUE NONCLUSTERED  ([RowGUID]) ON [PRIMARY]
GO
