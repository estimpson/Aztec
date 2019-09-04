CREATE TABLE [EDI_DICT].[DictionaryRaw]
(
[DictionaryVersion] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Dictionary] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [EDI_DICT].[DictionaryRaw] ADD CONSTRAINT [PK__Dictiona__FFEE7451ED808204] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
