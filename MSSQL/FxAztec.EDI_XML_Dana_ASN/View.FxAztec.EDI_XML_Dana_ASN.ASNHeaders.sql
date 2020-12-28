
/*
Create View.FxAztec.EDI_XML_Dana_ASN.ASNHeaders.sql
*/

use FxAztec
go

--drop table EDI_XML_Dana_ASN.ASNHeaders
if	objectproperty(object_id('EDI_XML_Dana_ASN.ASNHeaders'), 'IsView') = 1 begin
	drop view EDI_XML_Dana_ASN.ASNHeaders
end
go

create view EDI_XML_Dana_ASN.ASNHeaders
as
select
	ShipperID = s.id
,	iConnectID = es.IConnectID
,	TradingPartnerID = coalesce(nullif(es.trading_partner_code,''), 'Dana')
,	ShipTo = es.parent_destination
,	ShipToName = d.name
,	ShipToAddress = d.address_1
,	ShipToCity = upper(ltrim(rtrim(dbo.fn_SplitStringToArray(d.address_2, ',', 1))))
,	ShipToState = upper(left(ltrim(rtrim(dbo.fn_SplitStringToArray(d.address_2, ',', 2))),2))
,	ShipToZipCode = upper(ltrim(rtrim(dbo.fn_SplitStringToArray(ltrim(rtrim(dbo.fn_SplitStringToArray(d.address_2, ',', 2))), ' ', 0))))
,	PoolCode = esBOL.parent_destination
,	ShipDateTime = getdate()
,	ShipDate = convert(date, getdate())
,	ShipTime = convert(time, getdate())
,	EstimatedDeliveryDateTime = getdate()
--,	ShipDateTime = s.date_shipped
--,	ShipDate = convert(date, s.date_shipped)
--,	ShipTime = convert(time, s.date_shipped)
,	TimeZoneCode = 'ED'
,	GrossWeight = convert(int, round(s.gross_weight, 0))
,	NetWeight = convert(int, round(s.net_weight, 0))
,	PackageType = 'CTN90'
,	BOLQuantity = s.staged_objs
,	Carrier = s.ship_via
,	BOLCarrier = bol.scac_pickup
,	TransMode = coalesce(s.trans_mode, 'LT')
,	TruckNumber = coalesce(s.truck_number, convert(varchar(15), s.id))
,	BOLNumber = coalesce(s.bill_of_lading_number, s.id)
,	SupplierCode = es.supplier_code
,	SupplierName = p.name
,	SupplierPlant = s.plant
,	SupplierAddress = p.address_1
,	SupplierCity = upper(ltrim(rtrim(dbo.fn_SplitStringToArray(p.address_2, ',', 1))))
,	SupplierState = upper(left(ltrim(rtrim(dbo.fn_SplitStringToArray(p.address_2, ',', 2))),2))
,	SupplierZipCode = p.address_3
from
	dbo.shipper s
	join dbo.destination d
		on d.destination = s.destination
	join dbo.edi_setups es
		on s.destination = es.destination
	left join dbo.bill_of_lading bol
		join dbo.edi_setups esBOL
			on esBOL.destination = bol.destination
		on bol.bol_number = s.bill_of_lading_number
	left join dbo.destination p
		on p.destination = s.plant
where
	coalesce(s.type, 'N') in ('N', 'M')
	and es.asn_overlay_group like 'DAN'
go

return
update
	es
set es.asn_overlay_group = 'DAN'
,	es.auto_create_asn = 'N'
,	es.IConnectID = case when parent_destination = '1628' then '17161' when parent_destination = '1633' then 17160 else es.IConnectID end
from
	dbo.destination d
	join dbo.edi_setups es
		on es.destination = d.destination
where
	d.customer like 'DANA%'
	and es.parent_destination in ( '1633', '1628', '1715' )


go

select
	es.asn_overlay_group, es.auto_create_asn, es.parent_destination, d.*
from
	dbo.destination d
	join dbo.edi_setups es
		on es.destination = d.destination
where
	d.customer like 'DANA%'
	and es.parent_destination in ( '1633', '1628', '1715' )

select
	*
from
	EDI_XML_Dana_ASN.ASNHeaders ah
where
	ah.ShipperID in (89235, 89244)
