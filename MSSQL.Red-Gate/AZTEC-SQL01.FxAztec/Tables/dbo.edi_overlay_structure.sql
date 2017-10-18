CREATE TABLE [dbo].[edi_overlay_structure]
(
[overlay_group] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[data_set] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[column_name] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line] [int] NOT NULL,
[position] [int] NOT NULL,
[length] [int] NOT NULL,
[last_line_in_detail_section] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[filter_value] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[kanban] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[edi_overlay_structure] ADD CONSTRAINT [PK__edi_overlay_stru__17036CC0] PRIMARY KEY CLUSTERED  ([overlay_group], [data_set], [column_name], [line], [position]) ON [PRIMARY]
GO
