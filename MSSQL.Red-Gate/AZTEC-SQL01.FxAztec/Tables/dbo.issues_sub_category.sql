CREATE TABLE [dbo].[issues_sub_category]
(
[category] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_category] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[default_value] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[issues_sub_category] ADD CONSTRAINT [PK__issues_sub_categ__36470DEF] PRIMARY KEY CLUSTERED  ([category], [sub_category]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[issues_sub_category] ADD CONSTRAINT [FK__issues_su__categ__373B3228] FOREIGN KEY ([category]) REFERENCES [dbo].[issues_category] ([category])
GO
