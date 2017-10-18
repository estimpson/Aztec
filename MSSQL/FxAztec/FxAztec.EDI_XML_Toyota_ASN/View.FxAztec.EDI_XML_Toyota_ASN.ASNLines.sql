
/*
Create View.FxAztec.EDI_XML_Toyota_ASN.ASNLines.sql
*/

use FxAztec
go

--drop table EDI_XML_Toyota_ASN.ASNLines
if	objectproperty(object_id('EDI_XML_Toyota_ASN.ASNLines'), 'IsView') = 1 begin
	drop view EDI_XML_Toyota_ASN.ASNLines
end
go

create view EDI_XML_Toyota_ASN.ASNLines
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
go

select
	*
from
	EDI_XML_Toyota_ASN.ASNLines al
where
	al.ShipperID in (76053, 76054, 76023)
