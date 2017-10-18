CREATE TABLE [dbo].[requisition_group_account]
(
[group_code] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_no] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[requisition_group_account] ADD CONSTRAINT [PK__requisit__45EA8EB338EE7070] PRIMARY KEY CLUSTERED  ([group_code], [account_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [acct_index] ON [dbo].[requisition_group_account] ([account_no]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
