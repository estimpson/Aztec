CREATE TABLE [FT].[SecurityAccess_En]
(
[SecurityID] [varbinary] (256) NOT NULL,
[ResourceID] [varbinary] (256) NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [FT].[SecurityAccess_En] ADD CONSTRAINT [PK__Security__7B661144D445B977] PRIMARY KEY CLUSTERED  ([SecurityID], [ResourceID]) ON [PRIMARY]
GO
