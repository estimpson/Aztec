CREATE TABLE [FXSYS].[ExternalDWDefinition]
(
[Name] [varchar] (388) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GroupName] [sys].[sysname] NULL,
[UserName] [sys].[sysname] NULL,
[DWDefinition] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [FXSYS].[ExternalDWDefinition] ADD CONSTRAINT [PK__External__FFEE74514C564A9F] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [FXSYS].[ExternalDWDefinition] ADD CONSTRAINT [UQ__External__6353BB314F32B74A] UNIQUE NONCLUSTERED  ([Name], [GroupName], [UserName]) ON [PRIMARY]
GO
