CREATE TABLE [EDIToyota].[RemittanceHeaders]
(
[Status] [int] NOT NULL CONSTRAINT [DF__Remittanc__Statu__70CBE29B] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Remittance__Type__71C006D4] DEFAULT ((0)),
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
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Remittanc__RowCr__72B42B0D] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Remittanc__RowCr__73A84F46] DEFAULT (user_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Remittanc__RowMo__749C737F] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Remittanc__RowMo__759097B8] DEFAULT (user_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDIToyota].[RemittanceHeaders] ADD CONSTRAINT [PK__Remittan__FFEE74506EE39A29] PRIMARY KEY NONCLUSTERED  ([RowID]) ON [PRIMARY]
GO
