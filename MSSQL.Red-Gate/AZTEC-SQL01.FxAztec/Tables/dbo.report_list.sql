CREATE TABLE [dbo].[report_list]
(
[report] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[report_list] ADD CONSTRAINT [PK__report_l__21702C0A29AC2CE0] PRIMARY KEY CLUSTERED  ([report]) ON [PRIMARY]
GO
