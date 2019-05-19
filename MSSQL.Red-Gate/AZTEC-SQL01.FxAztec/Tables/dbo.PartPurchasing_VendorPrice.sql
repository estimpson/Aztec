CREATE TABLE [dbo].[PartPurchasing_VendorPrice]
(
[PartCode] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[VendorCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__PartPurch__Statu__562800F5] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__PartPurcha__Type__571C252E] DEFAULT ((0)),
[BaseBlanketPrice] [numeric] (20, 6) NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__PartPurch__RowCr__58104967] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__PartPurch__RowCr__59046DA0] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__PartPurch__RowMo__59F891D9] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__PartPurch__RowMo__5AECB612] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PartPurchasing_VendorPrice] ADD CONSTRAINT [PK__PartPurc__FFEE7451EFAEF6E0] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PartPurchasing_VendorPrice] ADD CONSTRAINT [UQ__PartPurc__A429CB68A580EDEF] UNIQUE NONCLUSTERED  ([PartCode], [VendorCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PartPurchasing_VendorPrice] ADD CONSTRAINT [FK__PartPurch__PartC__543FB883] FOREIGN KEY ([PartCode]) REFERENCES [dbo].[part] ([part])
GO
ALTER TABLE [dbo].[PartPurchasing_VendorPrice] ADD CONSTRAINT [FK__PartPurch__Vendo__5533DCBC] FOREIGN KEY ([VendorCode]) REFERENCES [dbo].[vendor] ([code])
GO
