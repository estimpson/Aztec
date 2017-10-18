SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[mvw_demand] (	
	part, 
	due_dt, 
	std_qty,
	first_key,
	second_key,
	plant,
	type,
	flag )			
as
select  od.part_number,
	od.due_date,
	od.std_qty,
	od.order_no,
	od.row_id,
	od.plant,
	od.type,
	od.flag
from 	order_detail od
	join order_header oh on oh.order_no = od.order_no
	join customer_service_status css on css.status_name = oh.cs_status 
	cross join parameters
where	od.ship_type = 'N' and
	css.status_type <> 'C' and
	datediff ( dd, getdate(), od.due_date ) <= parameters.days_to_process
GO
