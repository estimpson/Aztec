SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cs_ship_schedule_vw] 
as 
SELECT 	shipper.id,   
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
	shipper.net_weight,   
	shipper.picklist_printed,   
	shipper.invoice_number,   
	shipper.scheduled_ship_time,   
	shipper.cs_status,   
	shipper_detail.part_original,   
	shipper_detail.customer_part,   
	shipper_detail.customer_po,   
	shipper.staged_pallets,   
	shipper_detail.boxes_staged,   
	shipper_detail.order_no,
	shipper.truck_number,
	destination.name,
	customer.name cname
FROM 	shipper,   
	destination
	join customer on customer.customer = destination.customer,   
	customer_service_status,   
	shipper_detail  
WHERE 	shipper.destination = destination.destination and  
	shipper.cs_status = customer_service_status.status_name and  
	shipper_detail.shipper = shipper.id and  
	( shipper.status = 'O' OR  
	shipper.status = 'S' ) AND  
	isnull(shipper.type,'') <> 'R' and
	customer_service_status.status_type <> 'C'
GO
