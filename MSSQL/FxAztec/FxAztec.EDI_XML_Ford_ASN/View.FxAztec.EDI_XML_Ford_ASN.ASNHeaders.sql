
/*
Create View.FxAztec.EDI_XML_Ford_ASN.ASNHeaders.sql
*/

use FxAztec
go

--drop table EDI_XML_Ford_ASN.ASNHeaders
if	objectproperty(object_id('EDI_XML_Ford_ASN.ASNHeaders'), 'IsView') = 1 begin
	drop view EDI_XML_Ford_ASN.ASNHeaders
end
go

create view EDI_XML_Ford_ASN.ASNHeaders
as
select
	ShipperID = s.id
,	iConnectID = es.IConnectID
,	TradingPartnerID = es.trading_partner_code
,	ShipDateTime = s.date_shipped
,	ShipDate = convert(date, s.date_shipped)
,	ShipTime = convert(time, s.date_shipped)
,	GrossWeight = convert(int, round(s.gross_weight, 0))
,	NetWeight = convert(int, round(s.net_weight, 0))
,	PackageType =
		case
			when s.staged_pallets > 0 then 'PLT90'
			else 'CTN90'
		end
,	BOLQuantity =
		case
			when s.staged_pallets > 0 then s.staged_pallets
			else s.staged_objs
		end
,	Carrier = s.ship_via
,	BOLCarrier = coalesce(s.bol_carrier, s.ship_via)
,	TransMode = s.trans_mode
,	LocationQualifier =
		case
			when s.trans_mode = 'E' then null
			when s.trans_mode in ('A', 'AE') then 'OR'
			when es.pool_code != '' then 'PP'
		end
,	PoolCode =
		case
			when s.trans_mode = 'E' then null
			when s.trans_mode in ('A', 'AE') then 'DTW'
			else es.pool_code
		end
,	EquipmentType = es.equipment_description
,	TruckNumber = s.truck_number
,	PRONumber = s.pro_number
,	BOLNumber =
		case
			when es.parent_destination = 'milkrun' then substring(es.material_issuer, datepart(dw, s.date_shipped)*2-1, 2) + right('0'+convert(varchar, datepart(month, s.date_shipped)),2) + right('0'+convert(varchar, datepart(day, s.date_shipped)),2)
			else convert(varchar, s.bill_of_lading_number)
		end
,	ShipTo = left(s.destination, 5)
,	SupplierCode = es.supplier_code
--,	*
from
	dbo.shipper s
	join dbo.edi_setups es
		on s.destination = es.destination
		and es.asn_overlay_group like 'FD%'
	join dbo.destination d
		on d.destination = s.destination
where
	coalesce(s.type, 'N') in ('N', 'M')
	--and s.id = 75964
go

select
	*
from
	EDI_XML_Ford_ASN.ASNHeaders ah
where
	ah.ShipperID in (75979, 75964, 75945, 75990)
	and
		(	select
				count(*)
			from
				dbo.shipper_detail sd
			where
				sd.shipper = ah.ShipperID
		) > 1
