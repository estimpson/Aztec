SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cs_ship_history_summary_vw] 
as 
select	shipper.id,   
	shipper.destination,   
	shipper.date_stamp,   
	shipper.ship_via,   
	shipper.bill_of_lading_number,   
	shipper.staged_objs,   
	shipper.plant,   
	shipper.printed,   
	shipper.customer,   
	shipper.gross_weight,   
	shipper.pro_number,   
	shipper.status,   
	shipper.notes,   
	shipper.type,   
	destination.name,   
	shipper.net_weight,   
	shipper.picklist_printed,   
	shipper.invoice_number,   
	shipper.scheduled_ship_time,   
	shipper.cs_status,   
	shipper.staged_pallets,
	isnull(customer.name,vendor.name) vname,
	isnull(bill_of_lading.printed,'N') bol_printed
from	shipper
	left outer join bill_of_lading on bill_of_lading.bol_number = shipper.bill_of_lading_number,   
	destination
	join customer on customer.customer = destination.customer
	left outer join vendor on vendor.code = destination.vendor,   
	customer_service_status
where	( shipper.destination = destination.destination ) and  
	( shipper.cs_status = customer_service_status.status_name ) and  
	( shipper.status = 'C' OR shipper.status = 'Z' ) and 
	customer_service_status.status_type <> 'C' and
	( shipper.type = 'V' or shipper.type = 'O' or shipper.type = 'Q'  or shipper.type is null )
GO
