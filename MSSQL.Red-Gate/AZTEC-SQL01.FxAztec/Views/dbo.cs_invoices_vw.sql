SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cs_invoices_vw]  as
SELECT	invoice_number,   
	id,   
	date_shipped,   
	ship_via,   
	invoice_printed,   
	shipper.notes,   
	shipper.type,   
	shipping_dock,   
	status,   
	aetc_number,   
	freight_type,   
	printed,   
	bill_of_lading_number,   
	model_year_desc,   
	model_year,   
	location,   
	staged_objs,   
	shipper.plant,   
	invoiced,   
	freight,   
	tax_percentage,   
	total_amount,   
	gross_weight,   
	net_weight,   
	tare_weight,   
	responsibility_code,   
	trans_mode,   
	pro_number,   
	time_shipped,   
	truck_number,   
	seal_number,   
	shipper.terms,   
	tax_rate,   
	staged_pallets,   
	container_message,   
	picklist_printed,   
	dropship_reconciled,   
	date_stamp,   
	platinum_trx_ctrl_num,   
	posted,   
	scheduled_ship_time,
	customer.name as customer_name,
	destination.name as destination_name,
	shipper.destination,   
	shipper.customer
FROM	shipper
		join destination on destination.destination = shipper.destination
		join customer on customer.customer = destination.customer
WHERE	isnull(invoice_number,0) > 0
GO
