SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cdivw_getreleases] (	
	order_no,
	part,
	due_date,
	release_no,
	quantity,
	committedqty)
as
select	od.order_no, od.part_number, convert(varchar(10), od.due_date, 110) due, od.release_no, od.quantity, od.committed_qty
from	order_detail od
	join order_header oh on oh.order_no = od.order_no
where	isnull(oh.status,'O') = 'O' and
	od.committed_qty < od.quantity and 
	od.release_no > ''
group by od.order_no, od.part_number, convert(varchar(10), od.due_date, 110), od.release_no, od.quantity, od.committed_qty
GO
