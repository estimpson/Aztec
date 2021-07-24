SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [EDI_XML_Dana_ASN].[ASNOrders]
as
select
	ShipperID	= s.id
,	CustomerPart = dbo.fn_SplitStringToArray(sd.customer_part, ' ', 1)
,	QtyPacked = convert(int, round(sd.alternative_qty, 0))
,	UnitPacked = sd.alternative_unit
,	AccumQty = convert(int, round(sd.accum_shipped, 0))
,	CustomerPO = sd.customer_po
,	GrossWeight = convert(int, round(sd.gross_weight, 0))
,	NetWeight = convert(int, round(sd.net_weight, 0))
,	RowNumber = row_number() over (partition by s.id order by sd.customer_part)
from
	dbo.shipper s
	join dbo.edi_setups es
		on s.destination = es.destination
		and es.asn_overlay_group like 'DAN'
	join dbo.destination d
		on d.destination = s.destination
	join dbo.shipper_detail sd
		join dbo.order_header oh
			on oh.order_no = sd.order_no
			and oh.blanket_part = sd.part
		on sd.shipper = s.id
where
	coalesce(s.type, 'N') in
		( 'N', 'M' )
GO
