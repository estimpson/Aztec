CREATE TABLE [EDITOYO].[StagingShipScheduleHeaders]
(
[Status] [int] NOT NULL CONSTRAINT [DF__StagingSh__Statu__743193D4] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__StagingShi__Type__7525B80D] DEFAULT ((0)),
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
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__StagingSh__RowCr__7619DC46] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__StagingSh__RowCr__770E007F] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__StagingSh__RowMo__780224B8] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__StagingSh__RowMo__78F648F1] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDITOYO].[StagingShipScheduleHeaders] ADD CONSTRAINT [PK__StagingS__FFEE7450086D96AB] PRIMARY KEY NONCLUSTERED  ([RowID]) ON [PRIMARY]
GO
