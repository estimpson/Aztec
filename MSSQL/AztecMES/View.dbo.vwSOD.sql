
/*
Create table fx21st.dbo.vwSOD
*/

--use fx21st
--go

--drop table dbo.vwSOD
if	objectproperty(object_id('dbo.vwSOD'), 'IsView') = 1 begin
	drop view dbo.vwSOD
end
go

create view dbo.vwSOD
as
select
    OrderNO = order_no
,	LineID = id
,	ShipDT = due_date
,	Part = part_number
,	StdQty = std_qty
from
    dbo.order_detail od
where
    std_qty > 0
go

