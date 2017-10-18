CREATE TABLE [EDI].[Cooper_830_Headers]
(
[Status] [int] NOT NULL CONSTRAINT [DF__Cooper_83__Statu__55174480] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Cooper_830__Type__560B68B9] DEFAULT ((0)),
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
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Cooper_83__RowCr__56FF8CF2] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Cooper_83__RowCr__57F3B12B] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Cooper_83__RowMo__58E7D564] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Cooper_83__RowMo__59DBF99D] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI].[Cooper_830_Headers] ADD CONSTRAINT [PK__Cooper_8__FFEE7450532EFC0E] PRIMARY KEY NONCLUSTERED  ([RowID]) ON [PRIMARY]
GO
