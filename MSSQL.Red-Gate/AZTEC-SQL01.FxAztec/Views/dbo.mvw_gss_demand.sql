SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[mvw_gss_demand]
as
SELECT	order_detail.part_number,   
	order_detail.quantity,   
	order_detail.assigned,   
	order_detail.order_no,   
	order_detail.due_date,   
	order_detail.committed_qty,   
	order_detail.release_no,   
	order_detail.suffix,   
	order_detail.alternate_price as price,
	order_detail.destination
FROM 	order_detail, order_header, customer_service_status  
WHERE 	order_detail.quantity > IsNull ( order_detail.committed_qty, 0 )  and  
	order_detail.ship_type = 'N'  and
	order_header.order_no = order_detail.order_no and
	order_header.cs_status = customer_service_status.status_name and
	customer_service_status.status_type <> 'C'
GO
