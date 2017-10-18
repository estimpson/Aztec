CREATE TABLE [dbo].[FordServiceOrders]
(
[CustomerPart] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CustomerPO] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShipTo] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FordServiceOrders] ADD CONSTRAINT [PK__FordServ__14EA0195485EC9E5] PRIMARY KEY CLUSTERED  ([CustomerPart], [CustomerPO], [ShipTo]) ON [PRIMARY]
GO
