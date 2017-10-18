CREATE TABLE [dbo].[temp_bomec_stack]
(
[parent_part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_level] [smallint] NULL,
[start_datetime] [datetime] NULL,
[end_datetime] [datetime] NULL,
[substitute_part] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[spid] [int] NOT NULL
) ON [PRIMARY]
GO
