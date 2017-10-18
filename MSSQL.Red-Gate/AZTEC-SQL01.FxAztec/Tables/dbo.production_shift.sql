CREATE TABLE [dbo].[production_shift]
(
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[machine] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tool] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_stamp] [datetime] NULL,
[time_stamp] [datetime] NULL,
[type] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[production_time] [numeric] (10, 2) NULL,
[start_time] [datetime] NULL,
[stop_time] [datetime] NULL,
[production_rate] [numeric] (10, 2) NULL,
[fixtures_cavities] [numeric] (10, 2) NULL,
[transaction_number] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[transaction_timestamp] [datetime] NOT NULL,
[data_source] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[acum_production_qty] [numeric] (20, 6) NULL,
[average_cycle_time] [numeric] (5, 0) NULL,
[quantity] [numeric] (20, 6) NULL,
[work_order_number] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[production_shift] ADD CONSTRAINT [PK__producti__F2B484DF7908F585] PRIMARY KEY CLUSTERED  ([part], [transaction_timestamp]) ON [PRIMARY]
GO
