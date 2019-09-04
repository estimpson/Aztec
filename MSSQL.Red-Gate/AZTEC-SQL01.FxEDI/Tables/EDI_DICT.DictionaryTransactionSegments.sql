CREATE TABLE [EDI_DICT].[DictionaryTransactionSegments]
(
[DictionaryVersion] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TransactionType] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SegmentOrdinal] [int] NULL,
[SegmentCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Usage] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OccurrencesMin] [int] NULL,
[OccurrencesMax] [int] NULL,
[DictionaryRowID] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [EDI_DICT].[DictionaryTransactionSegments] ADD CONSTRAINT [UQ__Dictiona__D96918C6331F098E] UNIQUE NONCLUSTERED  ([DictionaryVersion], [TransactionType], [SegmentOrdinal]) ON [PRIMARY]
GO
