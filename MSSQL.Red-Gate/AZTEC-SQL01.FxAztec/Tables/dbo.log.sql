CREATE TABLE [dbo].[log]
(
[spid] [int] NOT NULL,
[id] [int] NOT NULL,
[message] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[log] ADD CONSTRAINT [PK__log__1590259A] PRIMARY KEY CLUSTERED  ([spid], [id]) ON [PRIMARY]
GO
