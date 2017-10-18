CREATE TABLE [dbo].[part_customer_price_import]
(
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[effective_date] [datetime] NULL,
[blanket_price] [numeric] (20, 6) NULL,
[usercode] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[username] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[changed_date] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[part_customer_price_import] ADD CONSTRAINT [PK__part_cus__70F2BC6F7D8E7ED7] PRIMARY KEY CLUSTERED  ([part], [customer]) ON [PRIMARY]
GO
