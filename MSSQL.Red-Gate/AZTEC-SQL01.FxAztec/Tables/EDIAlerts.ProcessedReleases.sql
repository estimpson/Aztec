CREATE TABLE [EDIAlerts].[ProcessedReleases]
(
[Status] [int] NOT NULL CONSTRAINT [DF__Processed__Statu__3A075444] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__ProcessedR__Type__3AFB787D] DEFAULT ((0)),
[EDIGroup] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TradingPartner] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocumentType] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AlertType] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReleaseNo] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToCode] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConsigneeCode] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipFromCode] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPart] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPO] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerModelYear] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Processed__RowCr__3BEF9CB6] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Processed__RowCr__3CE3C0EF] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Processed__RowMo__3DD7E528] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Processed__RowMo__3ECC0961] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDIAlerts].[ProcessedReleases] ADD CONSTRAINT [PK__Processe__FFEE745064D27221] PRIMARY KEY NONCLUSTERED  ([RowID]) ON [PRIMARY]
GO
