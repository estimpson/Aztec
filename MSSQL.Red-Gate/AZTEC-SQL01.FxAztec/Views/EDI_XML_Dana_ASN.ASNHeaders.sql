SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [EDI_XML_Dana_ASN].[ASNHeaders]
as
select
	ShipperID = s.id
,	iConnectID = es.IConnectID
,	TradingPartnerID = coalesce(nullif(es.trading_partner_code,''), 'Dana')
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
,	TransMode = coalesce(s.trans_mode, 'LT')
,	TruckNumber = coalesce(s.truck_number, convert(varchar(15), s.id))
,	BOLNumber = coalesce(s.bill_of_lading_number, s.id)
,	SupplierCode = es.supplier_code
from
	dbo.shipper s
	join dbo.edi_setups es
		on s.destination = es.destination
	left join dbo.bill_of_lading bol
		join dbo.edi_setups esBOL
			on esBOL.destination = bol.destination
		on bol.bol_number = s.bill_of_lading_number
where
	coalesce(s.type, 'N') in ('N', 'M')
	and es.asn_overlay_group like 'DAN'
GO
