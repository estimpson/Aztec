CREATE TABLE [dbo].[unit_measure]
(
[unit] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[unit_measure] ADD CONSTRAINT [PK__unit_measure__0425A276] PRIMARY KEY CLUSTERED  ([unit]) ON [PRIMARY]
GO
