CREATE TABLE [dbo].[sales_manager_code]
(
[code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sales_manager_code] ADD CONSTRAINT [PK__sales_manager_co__03FB8544] PRIMARY KEY CLUSTERED  ([code]) ON [PRIMARY]
GO
