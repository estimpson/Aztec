CREATE TABLE [FT].[Users]
(
[UserID] [uniqueidentifier] NOT NULL CONSTRAINT [DF__Users__UserID__21D6CC45] DEFAULT (newid()),
[OperatorCode] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LoginName] [sys].[sysname] NULL
) ON [PRIMARY]
GO
ALTER TABLE [FT].[Users] ADD CONSTRAINT [PK__Users__1788CCAC1FEE83D3] PRIMARY KEY CLUSTERED  ([UserID]) ON [PRIMARY]
GO
