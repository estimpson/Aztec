CREATE TABLE [EDI_DICT].[DictionarySegmentCodes]
(
[DictionaryVersion] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Code] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DictionaryRowID] [int] NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [EDI_DICT].[DictionarySegmentCodes] ADD CONSTRAINT [PK__Dictiona__FFEE7451DC891DFA] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [EDI_DICT].[DictionarySegmentCodes] ADD CONSTRAINT [UQ__Dictiona__B57C1856D6B22A34] UNIQUE NONCLUSTERED  ([DictionaryVersion], [Code]) ON [PRIMARY]
GO
