CREATE TABLE [dbo].[requisition_group_project]
(
[group_code] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[project_number] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[requisition_group_project] ADD CONSTRAINT [PK__requisit__F4467B603CBF0154] PRIMARY KEY CLUSTERED  ([group_code], [project_number]) ON [PRIMARY]
GO
