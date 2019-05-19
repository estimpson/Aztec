CREATE TABLE [SPORTAL].[SupplierShipmentsASNLines]
(
[SupplierShipmentsASNRowID] [int] NOT NULL,
[Status] [int] NOT NULL CONSTRAINT [DF__SupplierS__Statu__3DAAFE2E] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__SupplierSh__Type__3E9F2267] DEFAULT ((0)),
[Part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Quantity] [decimal] (20, 6) NOT NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime2] NOT NULL CONSTRAINT [DF__SupplierS__RowCr__3F9346A0] DEFAULT (sysdatetime()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__SupplierS__RowCr__40876AD9] DEFAULT (suser_name()),
[RowModifiedDT] [datetime2] NOT NULL CONSTRAINT [DF__SupplierS__RowMo__417B8F12] DEFAULT (sysdatetime()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__SupplierS__RowMo__426FB34B] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [SPORTAL].[SupplierShipmentsASNLines] ADD CONSTRAINT [PK__Supplier__FFEE7451BAC8E6A8] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [idx_SupplierShipmentsASNLines_1] ON [SPORTAL].[SupplierShipmentsASNLines] ([SupplierShipmentsASNRowID], [Part], [Quantity]) ON [PRIMARY]
GO
