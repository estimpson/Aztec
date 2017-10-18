SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [EDI_XML_Toyota_Invoice].[InvoiceHeaders]
as
select
	ShipperID = s.id
,	iConnectID = es.IConnectID
,	TradingPartnerID = coalesce(nullif(es.trading_partner_code,''), 'TMMI')
,	InvoiceDate = convert(date, s.date_shipped)
,	InvoiceTime = convert(time, s.date_shipped)
,	md.ManifestNumber
,	md.CustomerPart
,	md.Quantity
,	UnitPrice = convert(numeric(9,4), sd.alternate_price)
,	KanbanCard = 'M390'
,	InvoiceNumber = '01350'
,	InvoiceAmount = md.Quantity * sd.alternate_price
from
	dbo.shipper s
	join shipper_detail sd
		on sd.shipper = s.id
	join dbo.edi_setups es
		on s.destination = es.destination
	join EDIToyota.Pickups mp
		on mp.ShipperID = s.id
	join EDIToyota.ManifestDetails md
		on md.PickupID= mp.RowID
		and sd.order_no = md.OrderNo
where
	coalesce(s.type, 'N') in ('N', 'M')
	and es.asn_overlay_group like 'T%'
GO
