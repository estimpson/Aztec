SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [EDI_XML_Toyota_ASN].[ASNLines]
as
select
	ShipperID = s.id
,	ReturnableContainer = 'M390'
,	SupplierCode = es.supplier_code
,	md.CustomerPart
,	md.ManifestNumber
,	md.Quantity
from
	dbo.shipper s
	join dbo.edi_setups es
		on es.destination = s.destination
	join EDIToyota.Pickups mp
		on mp.ShipperID = s.id
	join EDIToyota.ManifestDetails md
		on md.PickupID = mp.RowID
GO
