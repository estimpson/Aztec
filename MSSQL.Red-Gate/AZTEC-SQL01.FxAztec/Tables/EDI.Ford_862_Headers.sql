CREATE TABLE [EDI].[Ford_862_Headers]
(
[Status] [int] NOT NULL CONSTRAINT [DF__Ford_862___Statu__4B4DE324] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Ford_862_H__Type__4C42075D] DEFAULT ((0)),
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
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Ford_862___RowCr__4D362B96] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Ford_862___RowCr__4E2A4FCF] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Ford_862___RowMo__4F1E7408] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Ford_862___RowMo__50129841] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[Ford_862_Headers] ADD CONSTRAINT [PK__Ford_862__FFEE745049659AB2] PRIMARY KEY NONCLUSTERED  ([RowID]) ON [PRIMARY]
GO
