CREATE TABLE [dbo].[temp_pops]
(
[name] [varchar] (45) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[number] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[area] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[temp_pops] ADD CONSTRAINT [PK__temp_pops__02FC7413] PRIMARY KEY CLUSTERED  ([name], [number]) ON [PRIMARY]
GO
