CREATE TABLE [EDI].[Cooper_862_Headers]
(
[Status] [int] NOT NULL CONSTRAINT [DF__Cooper_86__Statu__12555CEA] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Cooper_862__Type__13498123] DEFAULT ((0)),
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
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Cooper_86__RowCr__143DA55C] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Cooper_86__RowCr__1531C995] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Cooper_86__RowMo__1625EDCE] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Cooper_86__RowMo__171A1207] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[Cooper_862_Headers] ADD CONSTRAINT [PK__Cooper_8__FFEE7450106D1478] PRIMARY KEY NONCLUSTERED  ([RowID]) ON [PRIMARY]
GO
