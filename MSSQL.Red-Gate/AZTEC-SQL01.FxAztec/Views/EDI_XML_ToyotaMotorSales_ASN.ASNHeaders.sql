SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [EDI_XML_ToyotaMotorSales_ASN].[ASNHeaders]
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
,	s2.CaseNumber
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
	cross apply
		(	select
		 		CaseNumber = '082' + right('00000' + convert(varchar(5), (right(datepart(year, max(s2.date_stamp)), 1) * 10000 + count(*) % 10000)), 5)
		 	from
		 		dbo.shipper s2
			where
				s2.destination = s.destination
				and datepart(year, s2.date_stamp) = datepart(year, s.date_stamp)
				and s2.id <= s.id
		) s2
where
	coalesce(s.type, 'N') in ('N', 'M')
	and es.asn_overlay_group like 'TMS'
GO
