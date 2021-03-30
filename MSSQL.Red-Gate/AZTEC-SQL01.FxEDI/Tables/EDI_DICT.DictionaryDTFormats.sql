CREATE TABLE [EDI_DICT].[DictionaryDTFormats]
(
[DictionaryVersion] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__Dictionar__Statu__68487DD7] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Dictionary__Type__693CA210] DEFAULT ((0)),
[FormatString] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Dictionar__RowCr__6A30C649] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Dictionar__RowCr__6B24EA82] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Dictionar__RowMo__6C190EBB] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Dictionar__RowMo__6D0D32F4] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI_DICT].[DictionaryDTFormats] ADD CONSTRAINT [PK__Dictiona__FFEE74517C52A47C] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
