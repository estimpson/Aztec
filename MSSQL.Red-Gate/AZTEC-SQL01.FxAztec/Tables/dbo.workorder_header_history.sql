CREATE TABLE [dbo].[workorder_header_history]
(
[work_order] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tool] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[due_date] [datetime] NULL,
[cycles_required] [numeric] (10, 0) NULL,
[cycles_completed] [numeric] (10, 0) NULL,
[machine_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_id] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[setup_time] [numeric] (6, 2) NULL,
[cycles_hour] [numeric] (6, 0) NULL,
[standard_pack] [numeric] (8, 0) NULL,
[sequence] [int] NOT NULL,
[cycle_time] [int] NULL,
[start_date] [datetime] NULL,
[start_time] [datetime] NULL,
[end_date] [datetime] NULL,
[end_time] [datetime] NULL,
[runtime] [numeric] (20, 6) NULL,
[employee] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accum_run_time] [numeric] (20, 6) NULL,
[cycle_unit] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[material_shortage] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_control_activated] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plant] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [numeric] (8, 0) NULL,
[destination] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[workorder_header_history] ADD CONSTRAINT [PK__workorde__80BCBFB33C89F72A] PRIMARY KEY CLUSTERED  ([work_order], [machine_no], [sequence]) ON [PRIMARY]
GO
