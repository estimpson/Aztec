CREATE TABLE [dbo].[activity_costs]
(
[parent_part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[activity] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cpt] [numeric] (20, 6) NULL,
[trans_qty] [int] NULL,
[amount] [numeric] (20, 6) NULL,
[material_cost] [numeric] (20, 6) NULL,
[labor] [numeric] (20, 6) NULL,
[burden] [numeric] (20, 6) NULL,
[vari_burden] [numeric] (20, 6) NULL,
[user_1] [numeric] (20, 6) NULL,
[user_2] [numeric] (20, 6) NULL,
[user_3] [numeric] (20, 6) NULL,
[user_4] [numeric] (20, 6) NULL,
[user_5] [numeric] (20, 6) NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sequence] [numeric] (5, 0) NULL,
[price] [numeric] (20, 6) NULL,
[cost] [numeric] (20, 6) NULL,
[multiplier] [numeric] (20, 6) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[activity_costs] ADD CONSTRAINT [PK__activity_costs__09DE7BCC] PRIMARY KEY CLUSTERED  ([parent_part], [activity], [location]) ON [PRIMARY]
GO
