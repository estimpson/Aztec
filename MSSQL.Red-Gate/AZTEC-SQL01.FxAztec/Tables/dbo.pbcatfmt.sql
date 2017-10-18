CREATE TABLE [dbo].[pbcatfmt]
(
[pbf_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pbf_frmt] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pbf_type] [smallint] NULL,
[pbf_cntr] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [pbcatf_x] ON [dbo].[pbcatfmt] ([pbf_name]) ON [PRIMARY]
GO
