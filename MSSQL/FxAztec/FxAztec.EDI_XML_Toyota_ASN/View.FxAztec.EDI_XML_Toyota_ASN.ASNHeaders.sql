
/*
Create View.FxAztec.EDI_XML_Toyota_ASN.ASNHeaders.sql
*/

use FxAztec
go

--drop table EDI_XML_Toyota_ASN.ASNHeaders
if	objectproperty(object_id('EDI_XML_Toyota_ASN.ASNHeaders'), 'IsView') = 1 begin
	drop view EDI_XML_Toyota_ASN.ASNHeaders
end
go

create view EDI_XML_Toyota_ASN.ASNHeaders
as
select
	ShipperID = s.id
,	iConnectID = es.IConnectID
,	TradingPartnerID = coalesce(nullif(es.trading_partner_code,''), 'TMMI')
,	ShipDateTime = s.date_shipped
,	ShipDate = convert(date, s.date_shipped)
,	ShipTime = convert(time, s.date_shipped)
,	TimeZoneCode = 'ED'
,	GrossWeight = convert(int, round(s.gross_weight, 0))
,	NetWeight = convert(int, round(s.net_weight, 0))
,	PackageType = 'CTN90'
,	BOLQuantity =
		case
			when es.trading_partner_code = 'TMMWV' then
				coalesce
					(	nullif(pickup.Racks, 0)
					,	s.staged_objs
					)
			else s.staged_objs
		end
,	Carrier = s.ship_via
,	TransMode = coalesce(s.trans_mode, 'LT')
,	TruckNumber = coalesce(s.truck_number, convert(varchar(15), s.id))
,	BOLNumber = coalesce(s.bill_of_lading_number, s.id)
,	SupplierCode = es.supplier_code
from
	dbo.shipper s
	join dbo.edi_setups es
		on s.destination = es.destination
	outer apply
		(	select
				Racks = sum(md.Racks)
			from
				EDIToyota.Pickups p
				join EDIToyota.ManifestDetails md
					on md.PickupID = p.RowID
			where
				p.ShipperID = s.id
		) pickup
where
	coalesce(s.type, 'N') in ('N', 'M')
	and es.asn_overlay_group like 'T%'
go

select
	*
from
	EDI_XML_Toyota_ASN.ASNHeaders
where
	ShipperID in (76053, 76054, 76055)

select
	*
from
	dbo.shipper s
	join dbo.shipper_detail sd
		on sd.shipper = s.id
where
	s.id = 76053