SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cs_orders_vw]
as 
-----------------------------------------------------------------------------------------
--	GPH	2/22/01	Included isnull function on status column in the where clause and
--		8:30am	also included order no. greater than 0 check as part of the where
--			clause.
-----------------------------------------------------------------------------------------
select 	oh.order_no,
	oh.order_date,
	oh.destination,
	oh.amount,
	oh.status,
	oh.notes,
	oh.customer,
	isnull(min(od.due_date),oh.due_date) due_date
from 	order_header oh
		left outer join order_detail od on oh.order_no = od.order_no,
	customer_service_status as css
where 	css.status_name = oh.cs_status and
	css.status_type <> 'C' and
	isnull(oh.status,'') <> 'C' and
	oh.order_no > 0
group by oh.order_no,
	oh.order_date,
	oh.destination,
	oh.amount,
	oh.status,
	oh.notes,
	oh.customer,
	oh.due_date
GO
