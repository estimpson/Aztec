CREATE TABLE [dbo].[salesrep]
(
[salesrep] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[commission_rate] [numeric] (7, 4) NOT NULL,
[commission_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[salesrep] ADD CONSTRAINT [PK__salesrep__693CA210] PRIMARY KEY CLUSTERED  ([salesrep]) ON [PRIMARY]
GO
