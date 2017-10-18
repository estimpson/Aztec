SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [EDIToyota].[ShipTos]
as
select
	ShipToCode = coalesce(ds.destination, es.destination)
,	EDIShipToCode = es.parent_destination
,	FOB = ds.fob
,	Carrier = ds.scac_code
,	TransMode = ds.trans_mode
,	FreightType = ds.freight_type
,	ShipperNote = ds.note_for_shipper
from
	dbo.destination_shipping ds
	join dbo.edi_setups es
		on es.destination = ds.destination
where
	trading_partner_code like '%TMM%'

GO
