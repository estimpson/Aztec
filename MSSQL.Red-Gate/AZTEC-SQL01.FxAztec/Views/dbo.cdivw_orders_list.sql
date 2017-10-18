SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[cdivw_orders_list]
as
select
	customerpo = Customer_po,
	customerpart = Customer_part,
	destination = destination,
	boxlabel = box_label,
	order_no = order_no,
	part =  blanket_part,
	duedate = due_date
from		dbo.order_header oh
where	exists (select 1 from dbo.order_detail od where od.order_no = oh.order_no and od.due_date >= dateadd(dd, -30, getdate()))
GO
