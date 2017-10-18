CREATE TABLE [dbo].[alternative_parts]
(
[main_part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[alt_part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[alternative_parts] ADD CONSTRAINT [PK__alternative_part__178D7CA5] PRIMARY KEY CLUSTERED  ([main_part], [alt_part]) ON [PRIMARY]
GO
