CREATE TABLE [FT].[StatusDefn]
(
[StatusGUID] [uniqueidentifier] NOT NULL CONSTRAINT [DF__StatusDef__Statu__52593CB8] DEFAULT (newid()),
[StatusTable] [sys].[sysname] NOT NULL,
[StatusColumn] [sys].[sysname] NOT NULL,
[StatusCode] [int] NOT NULL,
[StatusName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[HelpText] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__StatusDef__RowCr__534D60F1] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NULL CONSTRAINT [DF__StatusDef__RowCr__5441852A] DEFAULT (suser_sname())
) ON [PRIMARY]
GO
ALTER TABLE [FT].[StatusDefn] ADD CONSTRAINT [PK__StatusDe__3C1B6591C4F86806] PRIMARY KEY NONCLUSTERED  ([StatusGUID]) ON [PRIMARY]
GO
ALTER TABLE [FT].[StatusDefn] ADD CONSTRAINT [UQ__StatusDe__62DBBDE9F5115B16] UNIQUE CLUSTERED  ([StatusTable], [StatusColumn], [StatusCode]) ON [PRIMARY]
GO
