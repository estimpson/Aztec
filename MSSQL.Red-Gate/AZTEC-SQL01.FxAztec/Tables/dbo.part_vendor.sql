CREATE TABLE [dbo].[part_vendor]
(
[part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_part] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_standard_pack] [numeric] (20, 6) NULL,
[accum_received] [numeric] (20, 6) NULL,
[accum_shipped] [numeric] (20, 6) NULL,
[outside_process] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_over_received] [numeric] (20, 6) NULL,
[receiving_um] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_time] [numeric] (6, 2) NULL,
[min_on_order] [numeric] (20, 6) NULL,
[beginning_inventory_date] [datetime] NULL,
[note] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[part_vendor] ADD CONSTRAINT [PK_part_vendor1] PRIMARY KEY CLUSTERED  ([part], [vendor]) ON [PRIMARY]
GO
