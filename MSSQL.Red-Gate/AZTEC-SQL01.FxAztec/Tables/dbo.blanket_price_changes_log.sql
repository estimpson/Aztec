CREATE TABLE [dbo].[blanket_price_changes_log]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[old_effective_date] [datetime] NULL,
[new_effective_date] [datetime] NULL,
[current_blanket_price] [numeric] (20, 6) NULL,
[old_blanket_price] [numeric] (20, 6) NULL,
[new_blanket_price] [numeric] (20, 6) NULL,
[order_no] [numeric] (8, 0) NULL,
[usercode] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[username] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[changed_date] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[blanket_price_changes_log] ADD CONSTRAINT [PK__blanket___3213E83F6C63F2D5] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [changeddate_ix] ON [dbo].[blanket_price_changes_log] ([changed_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [customer_part_ix] ON [dbo].[blanket_price_changes_log] ([customer], [part]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [customer_part_changeddate_ix] ON [dbo].[blanket_price_changes_log] ([customer], [part], [changed_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [part_customer_ix] ON [dbo].[blanket_price_changes_log] ([part], [customer]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [part_customer_changeddate_ix] ON [dbo].[blanket_price_changes_log] ([part], [customer], [changed_date]) ON [PRIMARY]
GO
