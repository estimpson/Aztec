
/*
Create ScalarFunction.FxAztec.EDI_XML_Chrysler_ASN.SEG_LIN.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Chrysler_ASN.SEG_LIN'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Chrysler_ASN.SEG_LIN
end
go

create function EDI_XML_Chrysler_ASN.SEG_LIN
(	@productQualifier varchar(3)
,	@productNumber varchar(25)
,	@engineeringChangeQualifier varchar(3)
,	@engineeringChangeNumber varchar(25)
,	@returnableContainerQualifier varchar(3)
,	@returnableContainerNumber varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V2040.SEG_INFO('LIN')
			,	EDI_XML_V2040.DE('0235', @productQualifier)
			,	EDI_XML_V2040.DE('0234', @productNumber)
			,	case when @engineeringChangeNumber > '' then EDI_XML_V2040.DE('0235', @engineeringChangeQualifier) end
			,	case when @engineeringChangeNumber > '' then EDI_XML_V2040.DE('0234', @engineeringChangeNumber) end
			,	EDI_XML_V2040.DE('0235', @returnableContainerQualifier)
			,	EDI_XML_V2040.DE('0234', @returnableContainerNumber)
			for xml raw ('SEG-LIN'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_Chrysler_ASN.SEG_LIN('BP', '53034136AB', 'EC', 'C', 'RC', 'EXP0363032')

select
	EDI_XML_Chrysler_ASN.SEG_LIN('BP', '53034136AB', 'EC', '', 'RC', 'EXP0363032')
go

