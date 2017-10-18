CREATE TABLE [dbo].[temp_order_cum]
(
[order_no] [numeric] (8, 0) NOT NULL,
[our_cum] [numeric] (20, 6) NULL,
[the_cum] [numeric] (20, 6) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[temp_order_cum] ADD CONSTRAINT [PK__temp_order_cum__00200768] PRIMARY KEY CLUSTERED  ([order_no]) ON [PRIMARY]
GO
