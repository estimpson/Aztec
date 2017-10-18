CREATE TABLE [dbo].[Companies]
(
[CompanyCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__Companies__Compa__4DF610FC] DEFAULT ('0'),
[Status] [int] NOT NULL CONSTRAINT [DF__Companies__Statu__4EEA3535] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__Companies__Type__4FDE596E] DEFAULT ((0)),
[CompanyName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__Companies__RowCr__50D27DA7] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Companies__RowCr__51C6A1E0] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__Companies__RowMo__52BAC619] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__Companies__RowMo__53AEEA52] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Companies] ADD CONSTRAINT [PK__Companie__FFEE7451BDE8CE7C] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Companies] ADD CONSTRAINT [UQ__Companie__11A0134B9920FFFC] UNIQUE NONCLUSTERED  ([CompanyCode]) ON [PRIMARY]
GO
