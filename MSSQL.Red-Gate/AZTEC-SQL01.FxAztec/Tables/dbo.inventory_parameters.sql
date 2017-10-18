CREATE TABLE [dbo].[inventory_parameters]
(
[record_number] [float] NOT NULL,
[machine_number] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[jc_machine] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[jc_part] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[jc_packaging] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[jc_location_to] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[jc_operator] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[jc_number_of] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[jc_qty] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[jc_unit] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mi_machine] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mi_operator] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mi_serial] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mi_qty] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mi_unit] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bo_operator] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bo_serial] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bo_number_of] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bo_qty] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bo_unit] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[jc_allow_zero_qty] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[jc_parts_mode] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[limit_locations] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[jc_material_lot] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[limit_locations_jc] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[limit_locations_mi] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[limit_locations_tr] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[inventory_parameters] ADD CONSTRAINT [PK__inventory_parame__25518C17] PRIMARY KEY CLUSTERED  ([record_number]) ON [PRIMARY]
GO
