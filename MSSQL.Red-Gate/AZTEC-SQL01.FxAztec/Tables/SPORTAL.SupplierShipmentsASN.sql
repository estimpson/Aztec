CREATE TABLE [SPORTAL].[SupplierShipmentsASN]
(
[ShipperID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__SupplierS__Statu__5C799E11] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__SupplierSh__Type__5D6DC24A] DEFAULT ((0)),
[SupplierCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BOLNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Destination] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime2] NOT NULL CONSTRAINT [DF__SupplierS__RowCr__5E61E683] DEFAULT (sysdatetime()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__SupplierS__RowCr__5F560ABC] DEFAULT (suser_name()),
[RowModifiedDT] [datetime2] NOT NULL CONSTRAINT [DF__SupplierS__RowMo__604A2EF5] DEFAULT (sysdatetime()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__SupplierS__RowMo__613E532E] DEFAULT (suser_name()),
[RowGUID] [uniqueidentifier] NULL CONSTRAINT [DF__SupplierS__RowGU__17DA5B01] DEFAULT (newid())
) ON [PRIMARY]
GO
ALTER TABLE [SPORTAL].[SupplierShipmentsASN] ADD CONSTRAINT [PK__Supplier__FFEE74512E482776] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [idx_SupplierShipmentsASN_1] ON [SPORTAL].[SupplierShipmentsASN] ([ShipperID], [SupplierCode]) ON [PRIMARY]
GO
