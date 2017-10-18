CREATE TABLE [EDI].[Cooper_830_Releases]
(
[Status] [int] NOT NULL CONSTRAINT [DF__Cooper_83__Statu__4B8DDA46] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Cooper_830__Type__4C81FE7F] DEFAULT ((0)),
[RawDocumentGUID] [uniqueidentifier] NULL,
[ShipToCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPart] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPO] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ICCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReleaseNo] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReleaseQty] [int] NULL,
[ReleaseDT] [datetime] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Cooper_83__RowCr__4D7622B8] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Cooper_83__RowCr__4E6A46F1] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Cooper_83__RowMo__4F5E6B2A] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Cooper_83__RowMo__50528F63] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[Cooper_830_Releases] ADD CONSTRAINT [PK__Cooper_8__FFEE745149A591D4] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
