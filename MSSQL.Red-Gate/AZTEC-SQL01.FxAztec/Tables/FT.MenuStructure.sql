CREATE TABLE [FT].[MenuStructure]
(
[ParentMenuID] [uniqueidentifier] NOT NULL,
[ChildMenuID] [uniqueidentifier] NOT NULL,
[Sequence] [float] NULL
) ON [PRIMARY]
GO
ALTER TABLE [FT].[MenuStructure] ADD CONSTRAINT [PK__MenuStru__ECE174455832119F] PRIMARY KEY CLUSTERED  ([ParentMenuID], [ChildMenuID]) ON [PRIMARY]
GO
