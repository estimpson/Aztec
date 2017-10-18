SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [dbo].[ftsp_SalesOrder_Demand]
as
begin
SET TRANSACTION ISOLATION LEVEL
read uncommitted 
select	order_detail.destination, 
			order_detail.order_no, 
			part_number, 
			order_detail.customer_part, 
			quantity, order_header.our_cum as 
			OrderAccumShipped, 
			case when release_no like '%_F' and datepart(d, order_detail.due_date)>20 then dateadd(m,1, ft.fn_truncdate('m',dbo.order_detail.due_date)) else  order_detail.due_date end, 
			release_no, 
			(select max(date_shipped) from shipper_detail where order_no = order_detail.order_no and part not like 'CUM_CHANGE%') as LastShippeddate,
			(select max(qty_packed) from shipper_detail, shipper where shipper_detail.shipper = shipper.id and order_no = order_detail.order_no and shipper.status ='Z' and  part not like  'CUM_CHANGE%' and shipper.date_shipped = (select max(shipper.date_shipped) from shipper_detail, shipper where shipper_detail.shipper = shipper.id and order_no = order_detail.order_no and shipper.status ='Z' and  part not like  'CUM_CHANGE%')) as LastShippedQty
from		dbo.order_detail
join		order_header on dbo.order_detail.order_no = dbo.order_header.order_no
where	order_detail.due_date >= dateadd(dd, -60, getdate())
order by 4 ,1
SET TRANSACTION ISOLATION LEVEL
read committed 
end

GO
