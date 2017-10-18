CREATE TABLE [dbo].[limit_parts]
(
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[limit_parts] ADD CONSTRAINT [PK__limit_parts__2F10007B] PRIMARY KEY CLUSTERED  ([part]) ON [PRIMARY]
GO
