CREATE TABLE [dbo].[dimensions]
(
[dim_code] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dimension] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[delete_flag] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dim_qty] [numeric] (9, 3) NULL,
[varying_dimension] [numeric] (1, 0) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dimensions] ADD CONSTRAINT [PK__dimensio__0E01427E7F2BE32F] PRIMARY KEY CLUSTERED  ([dim_code], [dimension]) ON [PRIMARY]
GO
