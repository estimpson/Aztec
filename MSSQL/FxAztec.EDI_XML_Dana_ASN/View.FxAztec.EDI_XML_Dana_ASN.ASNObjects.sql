
/*
Create View.FxAztec.EDI_XML_Dana_ASN.ASNObjects.sql
*/

use FxAztec
go

--drop table EDI_XML_Dana_ASN.ASNObjects
if	objectproperty(object_id('EDI_XML_Dana_ASN.ASNObjects'), 'IsView') = 1 begin
	drop view EDI_XML_Dana_ASN.ASNObjects
end
go

create view EDI_XML_Dana_ASN.ASNObjects
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
,	Serial = at.Serial
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
		,	Serial = at.serial
		from
			dbo.audit_trail at
		where
			type = 'S'
	) at on
		at.shipper = s.id
		and at.part = sd.part
where
	coalesce(s.type, 'N') in
		( 'N', 'M' )
go

select
	*
from
	EDI_XML_Dana_ASN.ASNObjects al
where
	al.ShipperID in (89235, 89244)
