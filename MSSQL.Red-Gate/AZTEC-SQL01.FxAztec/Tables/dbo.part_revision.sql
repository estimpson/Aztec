CREATE TABLE [dbo].[part_revision]
(
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[revision] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[engineering_level] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[effective_datetime] [datetime] NOT NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[part_revision] ADD CONSTRAINT [PK__part_rev__5427B7C74A4E069C] PRIMARY KEY CLUSTERED  ([part], [revision], [engineering_level]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_part_revision_eff_dt] ON [dbo].[part_revision] ([effective_datetime]) ON [PRIMARY]
GO
