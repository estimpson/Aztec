CREATE TABLE [dbo].[requisition_project_number]
(
[project_number] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[requisition_project_number] ADD CONSTRAINT [PK__requisit__5C6A7B0D4830B400] PRIMARY KEY CLUSTERED  ([project_number]) ON [PRIMARY]
GO
