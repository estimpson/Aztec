CREATE TABLE [EDI_DICT].[DictionarySegmentContents]
(
[DictionaryVersion] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ContentType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Segment] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ElementOrdinal] [int] NULL,
[ElementCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ElementUsage] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DictionaryRowID] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [EDI_DICT].[DictionarySegmentContents] ADD CONSTRAINT [UQ__Dictiona__43B3A4F25F6C0FE7] UNIQUE NONCLUSTERED  ([DictionaryVersion], [ContentType], [Segment], [ElementOrdinal]) ON [PRIMARY]
GO
