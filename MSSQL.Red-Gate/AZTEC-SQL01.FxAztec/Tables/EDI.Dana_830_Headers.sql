CREATE TABLE [EDI].[Dana_830_Headers]
(
[Status] [int] NOT NULL CONSTRAINT [DF__Dana_830___Statu__16E507DD] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Dana_830_H__Type__17D92C16] DEFAULT ((0)),
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
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Dana_830___RowCr__18CD504F] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Dana_830___RowCr__19C17488] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Dana_830___RowMo__1AB598C1] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Dana_830___RowMo__1BA9BCFA] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[Dana_830_Headers] ADD CONSTRAINT [PK__Dana_830__FFEE745014FCBF6B] PRIMARY KEY NONCLUSTERED  ([RowID]) ON [PRIMARY]
GO
