CREATE TABLE [dbo].[partplantimport]
(
[po] [int] NOT NULL,
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[plant] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[partplantimport] ADD CONSTRAINT [PK__partplan__321403CB682A18F4] PRIMARY KEY CLUSTERED  ([po]) ON [PRIMARY]
GO
