CREATE TABLE [dbo].[CompanyPurchaseOrders]
(
[CompanyCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PONumber] [int] NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__CompanyPu__Statu__0269D93B] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__CompanyPur__Type__035DFD74] DEFAULT ((0)),
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__CompanyPu__RowCr__045221AD] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__CompanyPu__RowCr__054645E6] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__CompanyPu__RowMo__063A6A1F] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__CompanyPu__RowMo__072E8E58] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CompanyPurchaseOrders] ADD CONSTRAINT [PK__CompanyP__FFEE7451D405BF62] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CompanyPurchaseOrders] ADD CONSTRAINT [UQ__CompanyP__11A0134BAFE544E2] UNIQUE NONCLUSTERED  ([CompanyCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CompanyPurchaseOrders] ADD CONSTRAINT [FK__CompanyPu__Compa__008190C9] FOREIGN KEY ([CompanyCode]) REFERENCES [dbo].[Companies] ([CompanyCode])
GO
ALTER TABLE [dbo].[CompanyPurchaseOrders] ADD CONSTRAINT [FK__CompanyPu__PONum__0175B502] FOREIGN KEY ([PONumber]) REFERENCES [dbo].[po_header] ([po_number])
GO
