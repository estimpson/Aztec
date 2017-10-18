CREATE TABLE [dbo].[commodity]
(
[id] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[commodity] ADD CONSTRAINT [PK__commodity__48CFD27E] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
