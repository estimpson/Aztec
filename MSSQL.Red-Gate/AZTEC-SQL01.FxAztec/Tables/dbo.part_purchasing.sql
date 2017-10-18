CREATE TABLE [dbo].[part_purchasing]
(
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[buyer] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[min_order_qty] [numeric] (20, 6) NULL,
[reorder_trigger_qty] [numeric] (20, 6) NULL,
[min_on_hand_qty] [numeric] (20, 6) NULL,
[primary_vendor] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gl_account_code] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[part_purchasing] ADD CONSTRAINT [PK__part_purchasing__45344BC4] PRIMARY KEY CLUSTERED  ([part]) ON [PRIMARY]
GO
