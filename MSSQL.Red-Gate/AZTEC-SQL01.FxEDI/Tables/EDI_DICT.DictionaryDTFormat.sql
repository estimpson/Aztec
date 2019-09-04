CREATE TABLE [EDI_DICT].[DictionaryDTFormat]
(
[DictionaryVersion] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__Dictionar__Dicti__4F47C5E3] DEFAULT ('0'),
[Type] [int] NOT NULL CONSTRAINT [DF__Dictionary__Type__503BEA1C] DEFAULT ((0)),
[FormatString] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Dictionar__RowCr__51300E55] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Dictionar__RowCr__5224328E] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Dictionar__RowMo__531856C7] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Dictionar__RowMo__540C7B00] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI_DICT].[DictionaryDTFormat] ADD CONSTRAINT [PK__Dictiona__FFEE745104DDAA7C] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [EDI_DICT].[DictionaryDTFormat] ADD CONSTRAINT [UQ__Dictiona__70C257B468906C1A] UNIQUE NONCLUSTERED  ([DictionaryVersion], [Type]) ON [PRIMARY]
GO
