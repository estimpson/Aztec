SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [EDI_XML_Dana_ASN].[ASNLines]
as
select
	ShipperID	= s.id
,	CustomerPart = sd.customer_part
,	QtyPacked = convert(int, round(sd.alternative_qty, 0))
,	UnitPacked = sd.alternative_unit
,	AccumQty = convert(int, round(sd.accum_shipped, 0))
,	CustomerPO = sd.customer_po
,	GrossWeight = convert(int, round(sd.gross_weight, 0))
,	NetWeight = convert(int, round(sd.net_weight, 0))
,	BoxType = 'CTN90'
,	BoxQty = at.BoxQty
,	BoxCount = at.BoxCount
,	RowNumber = row_number() over (partition by s.id order by sd.customer_part /*, at.BoxCount*/)
--,	*
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
	join
	(	select
			at.shipper
		,	at.part
		,	BoxQty = at.quantity
		,	BoxCount = count(*)
		from
			dbo.audit_trail at
		where
			type = 'S'
		group by
			at.shipper
		,	at.part
		,	at.quantity
	) at on
		at.shipper = s.id
		and at.part = sd.part
where
	coalesce(s.type, 'N') in
		( 'N', 'M' )
GO
