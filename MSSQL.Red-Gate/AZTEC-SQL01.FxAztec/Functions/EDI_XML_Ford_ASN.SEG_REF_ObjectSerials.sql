SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_Ford_ASN].[SEG_REF_ObjectSerials]
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
GO
