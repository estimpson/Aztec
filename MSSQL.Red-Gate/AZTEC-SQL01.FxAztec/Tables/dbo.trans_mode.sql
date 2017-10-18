CREATE TABLE [dbo].[trans_mode]
(
[code] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsExpedite] [int] NULL,
[IsAETCRequired] [tinyint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[trans_mode] ADD CONSTRAINT [PK__trans_mode__139CF030] PRIMARY KEY CLUSTERED  ([code]) ON [PRIMARY]
GO
