SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [EDI_XML_MAGNA].[ASNPallets]
as
select
	ShipperID = s.id
,	CustomerPart = sd.customer_part
,	QtyPacked = convert(int, sd.alternative_qty)
,	Unit = 'EA'
,	AccumShipped = sd.accum_shipped
,	CustomerPO = ltrim(rtrim(sd.customer_po))
,	pallets.PalletSerial
,	pallets.BoxQty
,	pallets.BoxCount
from
	Fx.shipper s
	join Fx.shipper_detail sd
		on sd.shipper = s.id
	join Fx.order_header oh
		on oh.order_no = sd.order_no
	join FX.edi_setups es
		on es.destination = s.destination
		and es.asn_overlay_group like 'MAG%'
	cross apply
	(	select
	 		PalletSerial = nullif(at.parent_serial, 0)
		,	BoxQty = at.std_quantity
		,	BoxCount = count(*)
	 	from
	 		Fx.audit_trail at
		where
			at.shipper = convert(varchar(max), s.id)
			and at.type = 'S'
			and at.part = sd.part_original
			and coalesce(at.parent_serial, 0) >= 0
		group by
			nullif(at.parent_serial, 0)
		,	at.std_quantity
	) pallets
where
	coalesce(s.type, 'N') in ('N', 'M')
GO
