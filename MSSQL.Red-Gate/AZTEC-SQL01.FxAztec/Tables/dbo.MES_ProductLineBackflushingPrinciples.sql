CREATE TABLE [dbo].[MES_ProductLineBackflushingPrinciples]
(
[ProductLine] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__MES_Produ__Statu__2059637E] DEFAULT ((0)),
[BackflushingPrinciple] [int] NOT NULL CONSTRAINT [DF__MES_Produ__Backf__214D87B7] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__MES_Produ__RowCr__2241ABF0] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__MES_Produ__RowCr__2335D029] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__MES_Produ__RowMo__2429F462] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__MES_Produ__RowMo__251E189B] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MES_ProductLineBackflushingPrinciples] ADD CONSTRAINT [PK__MES_Prod__FFEE74511AA08A28] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MES_ProductLineBackflushingPrinciples] ADD CONSTRAINT [UQ__MES_Prod__8C0969521D7CF6D3] UNIQUE NONCLUSTERED  ([ProductLine]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MES_ProductLineBackflushingPrinciples] ADD CONSTRAINT [FK__MES_Produ__Produ__1F653F45] FOREIGN KEY ([ProductLine]) REFERENCES [dbo].[product_line] ([id])
GO
