CREATE TABLE [dbo].[MES_CommodityBackflushingPrinciples]
(
[Commodity] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__MES_Commo__Statu__2DB35E9C] DEFAULT ((0)),
[BackflushingPrinciple] [int] NOT NULL CONSTRAINT [DF__MES_Commo__Backf__2EA782D5] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__MES_Commo__RowCr__2F9BA70E] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__MES_Commo__RowCr__308FCB47] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__MES_Commo__RowMo__3183EF80] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__MES_Commo__RowMo__327813B9] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MES_CommodityBackflushingPrinciples] ADD CONSTRAINT [PK__MES_Comm__FFEE745127FA8546] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MES_CommodityBackflushingPrinciples] ADD CONSTRAINT [UQ__MES_Comm__FA0D573E2AD6F1F1] UNIQUE NONCLUSTERED  ([Commodity]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MES_CommodityBackflushingPrinciples] ADD CONSTRAINT [FK__MES_Commo__Commo__2CBF3A63] FOREIGN KEY ([Commodity]) REFERENCES [dbo].[commodity] ([id])
GO
