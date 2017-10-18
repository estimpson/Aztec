SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [FT].[ftsp_rpt_ShipmentHistory] ( @fromDate datetime, @ThroughDate datetime )
as

-- [FT].[ftsp_rpt_ShipmentHistory] '2011-06-01', '2011-06-30'
select
	case when s.type = 'M' then 'ManualInvoice' when s.type = 'V' then 'ReturnToVendor' when s.type = 'Q' then 'QuickShipper' when s.type = 'R' then 'RMA' else 'NormalShipper'  end ShipperType ,
	s.customer, 
	c.name,
	c.contact,
	c.phone,
	sd.customer_po CustomerPO,
	sd.customer_part CustomerPart,
	sd.part_original Part,
	sd.part_name PartName,
	s.date_shipped DateShipped,
	sd.alternative_qty QuantityShipped,
	sd.alternate_price Price,
	(sd.alternative_qty*sd.alternate_price) Extended,
	s.id ShipperID

from		
	shipper_detail sd
join		
	shipper s on sd.shipper = s.id
join
	customer c on s.customer = c.customer
where
	isNull(s.type,'N') != 'O' and
	s.date_shipped >= @fromDate and
	s.date_shipped < dateadd(dd, 1,  FT.fn_TruncDate('dd',@ThroughDate))
	
GO
