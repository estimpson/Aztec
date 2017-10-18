CREATE TABLE [FT].[PartRouter]
(
[Part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BufferTime] [numeric] (20, 6) NULL,
[RunRate] [numeric] (22, 15) NULL,
[CrewSize] [numeric] (20, 6) NULL
) ON [PRIMARY]
GO
ALTER TABLE [FT].[PartRouter] ADD CONSTRAINT [PK__PartRout__A15FB6947BE62D87] PRIMARY KEY CLUSTERED  ([Part]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_PartRouter_1] ON [FT].[PartRouter] ([Part], [BufferTime]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_PartRouter_2] ON [FT].[PartRouter] ([Part], [RunRate]) ON [PRIMARY]
GO
