CREATE TABLE [dbo].[price_promotion]
(
[promotion] [int] NOT NULL,
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[category] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price] [numeric] (20, 6) NOT NULL,
[start_date] [datetime] NOT NULL,
[end_date] [datetime] NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[price_promotion] ADD CONSTRAINT [PK__price_promotion__367C1819] PRIMARY KEY CLUSTERED  ([promotion]) ON [PRIMARY]
GO
