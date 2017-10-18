SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cdivw_getreleaseno] (	
	order_no,
	part,
	due_date,
	release_no)
as
select	od.order_no, od.part_number, convert(varchar(10), od.due_date, 110), min(od.release_no)
from	order_detail od
	join order_header oh on oh.order_no = od.order_no
where	od.committed_qty < od.quantity and 
	od.release_no > ''
group by od.order_no, od.part_number, convert(varchar(10), od.due_date, 110)
GO
