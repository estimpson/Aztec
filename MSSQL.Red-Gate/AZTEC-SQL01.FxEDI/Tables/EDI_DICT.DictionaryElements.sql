CREATE TABLE [EDI_DICT].[DictionaryElements]
(
[DictionaryVersion] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ElementCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ElementName] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ElementDataType] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ElementLengthMin] [int] NULL,
[ElementLengthMax] [int] NULL,
[DictionaryRowID] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [EDI_DICT].[DictionaryElements] ADD CONSTRAINT [UQ__Dictiona__292205629BF0F73A] UNIQUE NONCLUSTERED  ([DictionaryVersion], [ElementCode]) ON [PRIMARY]
GO
