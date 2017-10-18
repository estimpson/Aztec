CREATE TABLE [dbo].[part_customer_blanketprice_changes]
(
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[effective_date] [datetime] NOT NULL,
[blanket_price] [numeric] (20, 6) NOT NULL,
[activated] [int] NOT NULL CONSTRAINT [DF__part_cust__activ__7AB2122C] DEFAULT ((0)),
[usercode] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[username] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activated_date] [datetime] NULL
) ON [PRIMARY]
GO
