CREATE TABLE [dbo].[phone]
(
[name] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[namel] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[phone] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[title] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rem1] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rem2] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[car] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fax] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[home] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modem] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cat] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[phone] ADD CONSTRAINT [PK__phone__267ABA7A] PRIMARY KEY CLUSTERED  ([name], [namel]) ON [PRIMARY]
GO
