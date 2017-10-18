CREATE TABLE [dbo].[downtime]
(
[trans_date] [datetime] NOT NULL,
[machine] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reason_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reason_name] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[down_time] [numeric] (20, 6) NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[employee] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shift] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[job] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [numeric] (20, 6) NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[production_pointer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[data_source] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trans_time] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[downtime] ADD CONSTRAINT [PK__downtime__1980975106CD04F7] PRIMARY KEY CLUSTERED  ([trans_date], [machine], [trans_time]) ON [PRIMARY]
GO
