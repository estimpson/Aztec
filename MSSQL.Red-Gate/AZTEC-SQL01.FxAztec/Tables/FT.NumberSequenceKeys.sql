CREATE TABLE [FT].[NumberSequenceKeys]
(
[KeyName] [sys].[sysname] NOT NULL,
[NumberSequenceID] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [FT].[NumberSequenceKeys] ADD CONSTRAINT [PK__NumberSe__F0A2A336658C0CBD] PRIMARY KEY CLUSTERED  ([KeyName]) ON [PRIMARY]
GO
ALTER TABLE [FT].[NumberSequenceKeys] ADD CONSTRAINT [FK__NumberSeq__Numbe__249EF5AE] FOREIGN KEY ([NumberSequenceID]) REFERENCES [FT].[NumberSequence] ([NumberSequenceID])
GO
