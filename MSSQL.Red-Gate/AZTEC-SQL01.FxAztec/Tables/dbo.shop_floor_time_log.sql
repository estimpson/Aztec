CREATE TABLE [dbo].[shop_floor_time_log]
(
[log_date] [datetime] NOT NULL,
[shift] [smallint] NULL,
[operator] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[activity] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [numeric] (20, 6) NULL,
[labor_hours] [numeric] (10, 2) NULL,
[work_order] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[transaction_date_time] [datetime] NOT NULL,
[status] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[shop_floor_time_log] ADD CONSTRAINT [PK__shop_flo__9625447F5D2BD0E6] PRIMARY KEY CLUSTERED  ([operator], [transaction_date_time]) ON [PRIMARY]
GO
