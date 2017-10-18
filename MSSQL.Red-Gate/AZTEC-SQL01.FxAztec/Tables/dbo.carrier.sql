CREATE TABLE [dbo].[carrier]
(
[name] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[scac] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_mode] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[carrier] ADD CONSTRAINT [PK__carrier__6C190EBB] PRIMARY KEY CLUSTERED  ([name]) ON [PRIMARY]
GO
