CREATE TABLE [EDI].[Ford_830_Headers]
(
[Status] [int] NOT NULL CONSTRAINT [DF__Ford_830___Statu__383B0EB0] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Ford_830_H__Type__392F32E9] DEFAULT ((0)),
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
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Ford_830___RowCr__3A235722] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Ford_830___RowCr__3B177B5B] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Ford_830___RowMo__3C0B9F94] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Ford_830___RowMo__3CFFC3CD] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[Ford_830_Headers] ADD CONSTRAINT [PK__Ford_830__FFEE74503652C63E] PRIMARY KEY NONCLUSTERED  ([RowID]) ON [PRIMARY]
GO
