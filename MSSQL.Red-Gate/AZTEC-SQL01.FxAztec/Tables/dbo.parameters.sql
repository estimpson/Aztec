CREATE TABLE [dbo].[parameters]
(
[company_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_serial] [int] NOT NULL,
[default_rows] [int] NULL,
[next_issue] [int] NULL,
[sales_order] [int] NULL,
[shipper] [int] NULL,
[company_logo] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[show_program_name] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[purchase_order] [numeric] (10, 0) NULL,
[address_1] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_3] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[admin_password] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_interval] [int] NULL,
[next_invoice] [int] NULL,
[next_requisition] [int] NULL,
[delete_scrapped_objects] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ipa] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ipa_beginning_sequence] [int] NULL,
[audit_trail_delete] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invoice_add] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plant_required] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edit_po_number] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[over_receive] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone_number] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipping_label] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bol_number] [int] NULL,
[verify_packaging] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fiscal_year_begin] [datetime] NULL,
[sales_tax_account] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_account] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[populate_parts] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[populate_locations] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[populate_machines] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mandatory_lot_inventory] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_process_days] [int] NULL,
[set_asn_uop] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shop_floor_check_u1] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shop_floor_check_u2] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shop_floor_check_u3] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shop_floor_check_u4] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shop_floor_check_u5] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shop_floor_check_lot] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_control_message] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mandatory_qc_notes] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asn_directory] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[next_db_change] [int] NULL,
[fix_number] [int] NULL,
[auto_stage_for_packline] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ask_for_minicop] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[issue_file_location] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accounting_interface_db] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accounting_interface_type] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accounting_interface_login] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accounting_interface_pwd] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accounting_pbl_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accounting_cust_sync_dp] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accounting_vend_sync_db] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accounting_ap_dp_header] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accounting_ar_dp] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accounting_ap_dp_detail] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inv_reg_col] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[scale_part_choice] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accounting_profile] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accounting_type] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[next_voucher] [int] NULL,
[days_to_process] [int] NULL,
[include_setuptime] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sunday] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[monday] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tuesday] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[wednesday] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[thursday] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[friday] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[saturday] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[workhours_in_day] [int] NULL,
[order_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pallet_package_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[clear_after_trans_jc] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dda_required] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dda_formula_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipper_required] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[calc_mtl_cost] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[issues_environment_message] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[base_currency] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[currency_display_symbol] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[euro_enabled] [smallint] NULL,
[requisition] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[onhand_from_partonline] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[consolidate_mps] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[daily_horizon] [int] NULL,
[weekly_horizon] [int] NULL,
[fortnightly_horizon] [int] NULL,
[monthly_horizon] [int] NULL,
[next_workorder] [int] NULL,
[audit_deletion] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[mtr_parameters_u]
on [dbo].[parameters]
for update
as

declare	@shipper	integer,
	@invoice	integer
	
if update ( shipper ) or update ( next_invoice )
begin
	select	@shipper = shipper,
		@invoice = next_invoice
	from	inserted
	
	if isnull ( @shipper, 0 ) <> isnull ( @invoice, 0 )
		exec msp_sync_parm_shipper_invoice
end
GO
ALTER TABLE [dbo].[parameters] ADD CONSTRAINT [PK__parameters__5E9FE363] PRIMARY KEY CLUSTERED  ([company_name]) ON [PRIMARY]
GO
