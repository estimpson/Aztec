CREATE TABLE [EDI4010_WAUPACA].[ShipNoticeOrders]
(
[Status] [int] NOT NULL CONSTRAINT [DF__ShipNotic__Statu__61316BF4] DEFAULT ((0)),
[Type] [int] NOT NULL CONSTRAINT [DF__ShipNotice__Type__6225902D] DEFAULT ((0)),
[RawDocumentGUID] [uniqueidentifier] NULL,
[ShipperID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PurchaseOrder] [int] NOT NULL,
[RowID] [int] NOT NULL IDENTITY(1, 1),
[RowCreateDT] [datetime] NULL CONSTRAINT [DF__ShipNotic__RowCr__6319B466] DEFAULT (getdate()),
[RowCreateUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipNotic__RowCr__640DD89F] DEFAULT (suser_name()),
[RowModifiedDT] [datetime] NULL CONSTRAINT [DF__ShipNotic__RowMo__6501FCD8] DEFAULT (getdate()),
[RowModifiedUser] [sys].[sysname] NOT NULL CONSTRAINT [DF__ShipNotic__RowMo__65F62111] DEFAULT (suser_name())
) ON [PRIMARY]
GO
ALTER TABLE [EDI4010_WAUPACA].[ShipNoticeOrders] ADD CONSTRAINT [PK__ShipNoti__FFEE7451F0E91363] PRIMARY KEY CLUSTERED  ([RowID]) ON [PRIMARY]
GO
