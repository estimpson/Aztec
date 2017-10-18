CREATE TABLE [dbo].[destination_shipping]
(
[destination] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[scac_code] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_mode] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dock_code_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[model_year_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fob] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note_for_shipper] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note_for_bol] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[print_shipper_note] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[print_bol_note] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[allow_mult_po] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_day] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[will_call_customer] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[allow_overstage] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsAETCRequired] [tinyint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[destination_shipping] ADD CONSTRAINT [PK__destination_ship__1F0EA2DC] PRIMARY KEY CLUSTERED  ([destination]) ON [PRIMARY]
GO
