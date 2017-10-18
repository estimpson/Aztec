CREATE TABLE [dbo].[HtmlPageTemplates]
(
[PageTemplate] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[HtmlPageTemplates] ADD CONSTRAINT [PK__HtmlPage__3B43E6BBD737589D] PRIMARY KEY CLUSTERED  ([PageTemplate]) ON [PRIMARY]
GO
