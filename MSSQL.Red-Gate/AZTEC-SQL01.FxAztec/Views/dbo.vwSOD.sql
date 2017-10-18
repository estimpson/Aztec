SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[vwSOD]
as
select
	Plant = plant
,	OrderNO = order_no
,	LineID = id
,	ShipDT = due_date
,	Part = part_number
,	StdQty = std_qty
from
	dbo.order_detail od
where
	std_qty > 0
GO
