CREATE TABLE [dbo].[issues_category]
(
[category] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[default_value] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[issues_category] ADD CONSTRAINT [PK__issues_category__336AA144] PRIMARY KEY CLUSTERED  ([category]) ON [PRIMARY]
GO
