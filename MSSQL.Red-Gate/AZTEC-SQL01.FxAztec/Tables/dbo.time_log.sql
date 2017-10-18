CREATE TABLE [dbo].[time_log]
(
[id] [int] NOT NULL,
[employee] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_logged] [numeric] (5, 2) NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[log_date] [datetime] NOT NULL,
[log_time] [datetime] NOT NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source] [int] NULL,
[workorder] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[time_log] ADD CONSTRAINT [PK__time_log__D57B853F6D6238AF] PRIMARY KEY CLUSTERED  ([id], [log_date], [log_time]) ON [PRIMARY]
GO
