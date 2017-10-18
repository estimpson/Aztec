
/*
Create View.FxAztec.EDI_XML_Ford_ASN.ASNObjects.sql
*/

use FxAztec
go

--drop table EDI_XML_Ford_ASN.ASNObjects
if	objectproperty(object_id('EDI_XML_Ford_ASN.ASNObjects'), 'IsView') = 1 begin
	drop view EDI_XML_Ford_ASN.ASNObjects
end
go

create view EDI_XML_Ford_ASN.ASNObjects
as
select
	ShipperID = s.id
,	CustomerPart = sd.customer_part
,	QtyPacked = convert(int, round(sd.alternative_qty, 0))
,	BoxQty =  convert(int, round(at.std_quantity, 0))
,	BoxType = coalesce(case when pm.type = 'R' then at.package_type end, 'CTN90')
,	BoxSerial = at.serial
--,	*
from
	dbo.shipper s
	join dbo.edi_setups es
		on s.destination = es.destination
		and es.asn_overlay_group like 'FD%'
	join dbo.destination d
		on d.destination = s.destination
	join dbo.shipper_detail sd
		join dbo.order_header oh
			on oh.order_no = sd.order_no
			and oh.blanket_part = sd.part
		on sd.shipper = s.id
	join dbo.audit_trail at
		join dbo.package_materials pm on pm.code = at.package_type
		on at.type = 'S'
		and at.part = sd.part_original
		and at.shipper = convert(varchar, s.id)
where
	coalesce(s.type, 'N') in ('N', 'M')
	--and s.id = 75964
go

select
	*
from
	EDI_XML_Ford_ASN.ASNObjects ao
where
	ao.ShipperID in (75979, 75964, 75945, 75990)
	and
		(	select
				count(*)
			from
				dbo.shipper_detail sd
			where
				sd.shipper = ao.ShipperID
		) > 1
order by
	ao.CustomerPart
,	ao.BoxSerial
go

