SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cs_ship_history_vw] 
as 
select	distinct shipper,
	part_original,
	isnull(suffix,0) as suffix,
	part,
	qty_required,
	qty_packed,
	shipper.bill_of_lading_number as bol_number,	
	shipper_detail.operator,
	shipper.truck_number,
	shipper.pro_number,
	shipper.ship_via,
	shipper.date_shipped,
	shipper_detail.customer_part,
	shipper_detail.order_no,
	shipper_detail.customer_po,
	shipper.destination,
	shipper.customer,
	customer.name customer_name,
	destination.name destination_name
from 	shipper_detail 
	join shipper on id=shipper
	join destination on destination.destination = shipper.destination
	join customer on customer.customer = destination.customer
where	(shipper.status='Z' or shipper.status='C') and
	(shipper.type='O' or shipper.type='Q' or shipper.type='V' or shipper.type is null)
GO
