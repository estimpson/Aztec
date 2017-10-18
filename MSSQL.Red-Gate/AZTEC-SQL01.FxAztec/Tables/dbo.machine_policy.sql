CREATE TABLE [dbo].[machine_policy]
(
[machine] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[job_change] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[schedule_queue] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[start_stop_login] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_control] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[access_inventory_control] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[material_substitution] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[change_std_pack] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[change_packaging] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[change_unit] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[job_completion_delete] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[material_issue_delete] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[defects_delete] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[downtime_delete] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[smallest_downtime_increment] [int] NOT NULL,
[downtime_histogram_days] [int] NOT NULL,
[work_order_display_window] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[packaging_line] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operator_required] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[supervisorclose] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[machine_policy] ADD CONSTRAINT [PK__machine_policy__32E0915F] PRIMARY KEY CLUSTERED  ([machine]) ON [PRIMARY]
GO
