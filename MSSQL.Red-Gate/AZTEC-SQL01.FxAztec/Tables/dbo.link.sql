CREATE TABLE [dbo].[link]
(
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_no] [int] NOT NULL,
[order_detail_id] [int] NOT NULL,
[mps_origin] [int] NOT NULL,
[mps_row_id] [int] NOT NULL,
[quantity] [numeric] (20, 6) NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[link] ADD CONSTRAINT [PK__link__05D8E0BE] PRIMARY KEY CLUSTERED  ([type], [order_no], [order_detail_id], [mps_origin], [mps_row_id]) ON [PRIMARY]
GO
