
/*
Create ScalarFunction.FxAztec.EDI_XML_Ford_ASN.SEG_REF_ObjectSerials.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Ford_ASN.SEG_REF_ObjectSerials'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Ford_ASN.SEG_REF_ObjectSerials
end
go

create function EDI_XML_Ford_ASN.SEG_REF_ObjectSerials
(	@ShipperID int
,	@CustomerPart varchar(30)
,	@BoxType varchar(20)
,	@BoxQty int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml = ''
	
	select
		@xmlOutput = convert(xml, convert(varchar(max), @xmlOutput) + convert(varchar(max), EDI_XML_V2002FORD.SEG_REF('LS', 'S' + convert(varchar, ao.BoxSerial))))
	from
		EDI_XML_Ford_ASN.ASNObjects ao
	where
		ao.ShipperID = @ShipperID
		and ao.CustomerPart = @CustomerPart
		and coalesce(ao.BoxType, '!') = coalesce(@BoxType, '!')
		and ao.BoxQty = @BoxQty
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_Ford_ASN.SEG_REF_ObjectSerials(75964, '7C34 5598 HD', null, 100)
return
go

select
	ao.BoxSerial
from
	EDI_XML_Ford_ASN.ASNObjects ao
where
	ao.ShipperID = 75964
	and ao.CustomerPart = '7C34 5598 HD'