CREATE TABLE [EDI].[StagingDana_862_Headers]
(
[Status] [int] NOT NULL CONSTRAINT [DF__StagingDa__Statu__6A9C714B] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__StagingDan__Type__6B909584] DEFAULT ((0)),
[RawDocumentGUID] [uniqueidentifier] NULL,
[DocumentImportDT] [datetime] NULL,
[TradingPartner] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocType] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Version] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Release] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ControlNumber] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocumentDT] [datetime] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__StagingDa__RowCr__6C84B9BD] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__StagingDa__RowCr__6D78DDF6] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__StagingDa__RowMo__6E6D022F] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__StagingDa__RowMo__6F612668] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[StagingDana_862_Headers] ADD CONSTRAINT [PK__StagingD__FFEE745068B428D9] PRIMARY KEY NONCLUSTERED  ([RowID]) ON [PRIMARY]
GO
