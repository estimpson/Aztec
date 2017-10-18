CREATE TABLE [dbo].[dim_relation]
(
[dim_code] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dimension] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[delete_flag] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dim_qty] [numeric] (9, 3) NULL,
[relationship] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dim_relation] ADD CONSTRAINT [PK__dim_rela__E420623A02FC7413] PRIMARY KEY CLUSTERED  ([dim_code]) ON [PRIMARY]
GO
