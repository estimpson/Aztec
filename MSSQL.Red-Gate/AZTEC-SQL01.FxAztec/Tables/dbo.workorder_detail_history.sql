CREATE TABLE [dbo].[workorder_detail_history]
(
[workorder] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_required] [numeric] (20, 6) NULL,
[qty_completed] [numeric] (20, 6) NULL,
[parts_per_cycle] [numeric] (20, 6) NULL,
[run_time] [numeric] (20, 6) NULL,
[scrapped] [numeric] (20, 6) NULL,
[balance] [numeric] (20, 6) NULL,
[plant] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[parts_per_hour] [numeric] (20, 6) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[workorder_detail_history] ADD CONSTRAINT [PK__workorder_detail__22751F6C] PRIMARY KEY CLUSTERED  ([workorder], [part]) ON [PRIMARY]
GO
