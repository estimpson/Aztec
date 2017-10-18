CREATE TABLE [dbo].[part_gl_account]
(
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_type] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gl_account_no_db] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gl_account_no_cr] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[part_gl_account] ADD CONSTRAINT [PK__part_gl_account__3C0AD43D] PRIMARY KEY CLUSTERED  ([part], [tran_type]) ON [PRIMARY]
GO
