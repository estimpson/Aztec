
/*
Create View.FxAztec.EDI_XML_ToyotaMotorSales_ASN.ASNHeaders.sql
*/

use FxAztec
go

--drop table EDI_XML_ToyotaMotorSales_ASN.ASNHeaders
if	objectproperty(object_id('EDI_XML_ToyotaMotorSales_ASN.ASNHeaders'), 'IsView') = 1 begin
	drop view EDI_XML_ToyotaMotorSales_ASN.ASNHeaders
end
go

create view EDI_XML_ToyotaMotorSales_ASN.ASNHeaders
as
select
	ShipperID = s.id
,	iConnectID = es.IConnectID
,	TradingPartnerID = coalesce(nullif(es.trading_partner_code,''), 'Toyota Mot.(Sales)')
,	ShipTo = es.parent_destination
,	PoolCode = esBOL.parent_destination
,	ShipDateTime = s.date_shipped
,	ShipDate = convert(date, getdate())
,	ShipTime = convert(time, getdate())
--,	ShipDate = convert(date, s.date_shipped)
--,	ShipTime = convert(time, s.date_shipped)
,	TimeZoneCode = 'ED'
,	GrossWeight = convert(int, round(s.gross_weight, 0))
,	NetWeight = convert(int, round(s.net_weight, 0))
,	PackageType = 'CTN90'
,	BOLQuantity = s.staged_objs
,	Carrier = s.ship_via
,	BOLCarrier = bol.scac_pickup
,	TransMode = coalesce(nullif(s.trans_mode, ''), nullif(c.trans_mode, ''), 'LT')
,	TruckNumber = coalesce(s.truck_number, convert(varchar(15), s.id))
,	BOLNumber = coalesce(s.bill_of_lading_number, s.id)
,	SupplierCode = es.supplier_code
from
	dbo.shipper s
	left join dbo.carrier c
		on c.scac = s.ship_via
	join dbo.edi_setups es
		on s.destination = es.destination
	left join dbo.bill_of_lading bol
		join dbo.edi_setups esBOL
			on esBOL.destination = bol.destination
		on bol.bol_number = s.bill_of_lading_number
where
	coalesce(s.type, 'N') in ('N', 'M')
	and es.asn_overlay_group like 'TMS'
go

select
	*
from
	EDI_XML_ToyotaMotorSales_ASN.ASNHeaders ah
--where
--	ah.ShipperID in (89235, 89244)

select
	*
from
	dbo.carrier c
where
	c.scac in ('UPSN', 'UPSD')

select
	*
from
	dbo.audit_trail at
where
	at.shipper = '88928'