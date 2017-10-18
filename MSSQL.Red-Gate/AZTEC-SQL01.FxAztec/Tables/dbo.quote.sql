CREATE TABLE [dbo].[quote]
(
[quote_number] [int] NOT NULL,
[customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quote_date] [datetime] NULL,
[contact] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amount] [numeric] (20, 6) NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[destination] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesman] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[expire_date] [datetime] NULL,
[lock_flag] [smallint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[quote] ADD CONSTRAINT [PK__quote__4AB81AF0] PRIMARY KEY CLUSTERED  ([quote_number]) ON [PRIMARY]
GO
