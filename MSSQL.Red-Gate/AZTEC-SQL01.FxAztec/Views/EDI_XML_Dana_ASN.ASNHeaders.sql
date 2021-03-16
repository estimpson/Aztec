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
,	ProInvoice = coalesce(nullif(left(s.pro_number,30), ''), convert(varchar(30), s.invoice_number))
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
GO
