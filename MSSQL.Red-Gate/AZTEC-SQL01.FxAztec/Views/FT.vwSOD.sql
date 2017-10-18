SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [FT].[vwSOD]
as
--	Description:
--	Get open sales order details.
select
	OrderNO = od.order_no
,	ShipToCode = od.destination
,	ShipToName = d.name
,	BillToCode = d.customer
,	BillToName = c.name
,	LineID = od.id
,	Sequence = od.sequence
,	ShipDT = od.due_date
,	PartCode = od.part_number
,	StdQty = od.std_qty
from
	dbo.order_detail od
	join dbo.destination d on 
		od.destination = d.destination
	join dbo.customer c on
		d.customer = c.customer
where
	std_qty > 0
GO
