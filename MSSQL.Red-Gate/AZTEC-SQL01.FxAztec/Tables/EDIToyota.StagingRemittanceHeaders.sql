CREATE TABLE [EDIToyota].[StagingRemittanceHeaders]
(
[Status] [int] NOT NULL CONSTRAINT [DF__StagingRe__Statu__5DB90E27] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__StagingRem__Type__5EAD3260] DEFAULT ((0)),
[RawDocumentGUID] [uniqueidentifier] NULL,
[DocumentImportDT] [datetime] NULL,
[TradingPartner] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocType] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Version] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Release] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ControlNumber] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocumentDT] [datetime] NULL,
[RemittanceTotal] [numeric] (20, 6) NULL,
[CreditDebitFlag] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PaymentMethod] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PaymentFormat] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FunctionCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__StagingRe__RowCr__5FA15699] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__StagingRe__RowCr__60957AD2] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__StagingRe__RowMo__61899F0B] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__StagingRe__RowMo__627DC344] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDIToyota].[StagingRemittanceHeaders] ADD CONSTRAINT [PK__StagingR__FFEE74505BD0C5B5] PRIMARY KEY NONCLUSTERED  ([RowID]) ON [PRIMARY]
GO
