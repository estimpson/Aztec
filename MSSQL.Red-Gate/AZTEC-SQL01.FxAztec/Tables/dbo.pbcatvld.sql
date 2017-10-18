CREATE TABLE [dbo].[pbcatvld]
(
[pbv_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pbv_vald] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pbv_type] [smallint] NULL,
[pbv_cntr] [int] NULL,
[pbv_msg] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [pbcatv_x] ON [dbo].[pbcatvld] ([pbv_name]) ON [PRIMARY]
GO
