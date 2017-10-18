CREATE TABLE [dbo].[gt_comp_list]
(
[spid] [int] NOT NULL,
[part_number] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cur_level] [int] NOT NULL,
[processed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
