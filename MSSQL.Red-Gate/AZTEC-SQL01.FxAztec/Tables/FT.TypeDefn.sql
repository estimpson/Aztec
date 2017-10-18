CREATE TABLE [FT].[TypeDefn]
(
[TypeGUID] [uniqueidentifier] NOT NULL CONSTRAINT [DF__TypeDefn__TypeGU__4BCD0611] DEFAULT (newid()),
[TypeTable] [sys].[sysname] NOT NULL,
[TypeColumn] [sys].[sysname] NOT NULL,
[TypeCode] [int] NOT NULL,
[TypeName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[HelpText] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__TypeDefn__RowCre__4CC12A4A] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NULL CONSTRAINT [DF__TypeDefn__RowCre__4DB54E83] DEFAULT (suser_sname())
) ON [PRIMARY]
GO
ALTER TABLE [FT].[TypeDefn] ADD CONSTRAINT [PK__TypeDefn__0D59B00849E4BD9F] PRIMARY KEY NONCLUSTERED  ([TypeGUID]) ON [PRIMARY]
GO
ALTER TABLE [FT].[TypeDefn] ADD CONSTRAINT [UQ__TypeDefn__D59E7E70470850F4] UNIQUE CLUSTERED  ([TypeTable], [TypeColumn], [TypeCode]) ON [PRIMARY]
GO
