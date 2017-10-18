CREATE TABLE [EDI].[StagingDana_830_Headers]
(
[Status] [int] NOT NULL CONSTRAINT [DF__StagingDa__Statu__7DAF45BF] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__StagingDan__Type__7EA369F8] DEFAULT ((0)),
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
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__StagingDa__RowCr__7F978E31] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__StagingDa__RowCr__008BB26A] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__StagingDa__RowMo__017FD6A3] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__StagingDa__RowMo__0273FADC] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[StagingDana_830_Headers] ADD CONSTRAINT [PK__StagingD__FFEE74507BC6FD4D] PRIMARY KEY NONCLUSTERED  ([RowID]) ON [PRIMARY]
GO
