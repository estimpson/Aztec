CREATE TABLE [dbo].[customer_additional]
(
[customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[platinum_id] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_date] [datetime] NULL,
[end_date] [datetime] NULL,
[closure_rate] [numeric] (5, 2) NULL,
[ontime_rate] [numeric] (5, 2) NULL,
[return_rate] [numeric] (5, 2) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[customer_additional] ADD CONSTRAINT [PK__customer_additio__1955C986] PRIMARY KEY CLUSTERED  ([customer]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[customer_additional] ADD CONSTRAINT [FK__customer___custo__39F939F0] FOREIGN KEY ([customer]) REFERENCES [dbo].[customer] ([customer])
GO
