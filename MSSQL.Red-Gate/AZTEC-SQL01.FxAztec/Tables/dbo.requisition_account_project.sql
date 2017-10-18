CREATE TABLE [dbo].[requisition_account_project]
(
[account_number] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[project_number] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[requisition_account_project] ADD CONSTRAINT [PK__requisit__6A57011C2D7CBDC4] PRIMARY KEY CLUSTERED  ([account_number], [project_number]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [acct_indx] ON [dbo].[requisition_account_project] ([account_number]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
