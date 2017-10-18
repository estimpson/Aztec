
/*
Create function TableFunction.FxAztec.EDI_XML_Ford_ASN.ASNLines.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Ford_ASN.ASNLines'), 'IsTableFunction') = 1 begin
	drop function EDI_XML_Ford_ASN.ASNLines
end
go

create function EDI_XML_Ford_ASN.ASNLines
(	@shipperID int
)
returns @ASNLines table
(	ShipperID int
,	CustomerPart varchar(30)
,	QtyPacked int
,	UnitPacked char(2)
,	AccumQty int
,	CustomerPO varchar(25)
,	GrossWeight int
,	NetWeight int
,	BoxType varchar(20)
,	BoxQty int
,	BoxCount int
,	RowNumber int
)
as
begin
--- <Body>
	declare
		@at table
	(	Part varchar(25)
	,	BoxType varchar(20)
	,	BoxQty int
	,	BoxCount int
	)

	insert
		@at
	(	Part
	,	BoxType
	,	BoxQty
	,	BoxCount
	)
	select
		Part = at.part
	,	BoxType = coalesce(case when pm.type = 'R' then at.package_type end, 'CTN90')
	,	BoxQty = convert(int, round(at.std_quantity,0))
	,	BoxCount = count(*)
	from
		dbo.audit_trail at
		join dbo.package_materials pm
			on pm.code = at.package_type
	where
		at.shipper = convert(varchar, @shipperID)
		and at.type = 'S'
	group by
		at.part
	,	coalesce(case when pm.type = 'R' then at.package_type end, 'CTN90')
	,	at.std_quantity

	insert
		@ASNLines
	(	ShipperID
	,	CustomerPart
	,	QtyPacked
	,	UnitPacked
	,	AccumQty
	,	CustomerPO
	,	GrossWeight
	,	NetWeight
	,	BoxType
	,	BoxQty
	,	BoxCount
	,	RowNumber
	)
	select
		ShipperID = s.id
	,	CustomerPart = sd.customer_part
	,	QtyPacked = convert(int, round(sd.alternative_qty, 0))
	,	UnitPacked = sd.alternative_unit
	,	AccumQty =
			case
				when es.prev_cum_in_asn = 'Y'
					then convert(int, round(sd.accum_shipped - sd.alternative_qty, 0))
				else convert(int, round(sd.accum_shipped, 0))
			end
	,	CustomerPO = sd.customer_po
	,	GrossWeight = convert(int, round(sd.gross_weight, 0))
	,	NetWeight = convert(int, round(sd.net_weight, 0))
	,	BoxType = at.BoxType
	,	BoxQty = at.BoxQty
	,	BoxCount = at.BoxCount
	,	RowNumber = row_number() over (partition by s.id order by sd.customer_part, at.BoxCount)
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
		join @at at
			on at.Part = sd.part
	where
		coalesce(s.type, 'N') in ('N', 'M')
		and s.id = @shipperID
--- </Body>

---	<Return>
	return
end
go

select
	*
from
	EDI_XML_Ford_ASN.ASNLines(75964)