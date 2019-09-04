CREATE TABLE [EDI_DICT].[DictionaryElementValueCodes]
(
[DictionaryVersion] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ElementCode] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ValueCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DictionaryRowID] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [EDI_DICT].[DictionaryElementValueCodes] ADD CONSTRAINT [UQ__Dictiona__A52C526E43CA83F2] UNIQUE NONCLUSTERED  ([DictionaryVersion], [ElementCode], [ValueCode]) ON [PRIMARY]
GO
