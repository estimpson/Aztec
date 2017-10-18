CREATE TABLE [dbo].[asn_overlay_structure]
(
[overlay_group] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[column_name] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line] [int] NOT NULL,
[position] [int] NOT NULL,
[section] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[length] [int] NULL,
[hard_code_value] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[error] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[asn_overlay_structure] ADD CONSTRAINT [PK__asn_overlay_stru__7A672E12] PRIMARY KEY CLUSTERED  ([overlay_group], [column_name], [line], [position], [section]) ON [PRIMARY]
GO
