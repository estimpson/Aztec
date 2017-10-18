CREATE TABLE [dbo].[multireleases]
(
[id] [int] NOT NULL,
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rel_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quantity] [decimal] (20, 6) NULL,
[rel_date] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[multireleases] ADD CONSTRAINT [multirelease_pk] PRIMARY KEY CLUSTERED  ([id], [part], [rel_date]) ON [PRIMARY]
GO
