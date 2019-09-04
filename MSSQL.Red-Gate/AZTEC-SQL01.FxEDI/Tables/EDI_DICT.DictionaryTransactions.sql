CREATE TABLE [EDI_DICT].[DictionaryTransactions]
(
[DictionaryVersion] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TransactionType] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TransactionDescription] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DictionaryRowID] [int] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [EDI_DICT].[DictionaryTransactions] ADD CONSTRAINT [PK__Dictiona__FFEE745178EA71F3] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [EDI_DICT].[DictionaryTransactions] ADD CONSTRAINT [UQ__Dictiona__C24817797F3DD3F4] UNIQUE NONCLUSTERED  ([DictionaryVersion], [TransactionType]) ON [PRIMARY]
GO
