CREATE TABLE [dbo].[master_prod_sched]
(
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[due] [datetime] NOT NULL,
[qnty] [numeric] (20, 6) NOT NULL,
[source] [int] NOT NULL,
[source2] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[origin] [numeric] (8, 0) NOT NULL,
[rel_date] [datetime] NULL,
[tool] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[workcenter] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[machine] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[run_time] [numeric] (20, 6) NOT NULL,
[run_day] [numeric] (20, 6) NULL,
[dead_start] [datetime] NOT NULL,
[material] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[job] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[material_qnty] [numeric] (20, 6) NULL,
[setup] [numeric] (20, 6) NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field1] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field2] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field3] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field4] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field5] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sched_method] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_completed] [numeric] (20, 6) NULL,
[process] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tool_num] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[workorder] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_assigned] [numeric] (20, 6) NULL,
[due_time] [datetime] NULL,
[start_time] [datetime] NULL,
[id] [numeric] (12, 0) NOT NULL,
[parent_id] [numeric] (12, 0) NULL,
[begin_date] [datetime] NULL,
[begin_time] [datetime] NULL,
[end_date] [datetime] NULL,
[end_time] [datetime] NULL,
[po_number] [int] NULL,
[po_row_id] [int] NULL,
[week_no] [int] NULL,
[plant] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ai_row] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[master_prod_sched] ADD CONSTRAINT [PK__master_p__034CEB3D719CDDE7] PRIMARY KEY CLUSTERED  ([ai_row]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [mps_due] ON [dbo].[master_prod_sched] ([due]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [mps_part] ON [dbo].[master_prod_sched] ([part]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [mps_demand] ON [dbo].[master_prod_sched] ([source], [origin]) ON [PRIMARY]
GO
