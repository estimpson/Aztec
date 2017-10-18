CREATE TABLE [dbo].[process]
(
[id] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cycle_time] [int] NULL,
[cycle_unit] [int] NULL,
[operators] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[process] ADD CONSTRAINT [PK__process__2C3393D0] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
