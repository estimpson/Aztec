
/*
Create ScalarFunction.FxAztec.EDI_XML_Chrysler_ASN.SEG_ITA092.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Chrysler_ASN.SEG_ITA092'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Chrysler_ASN.SEG_ITA092
end
go

create function EDI_XML_Chrysler_ASN.SEG_ITA092
(	@chargeAmount numeric(9,2)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V2040.SEG_INFO('ITA')
			,	EDI_XML_V2040.DE('0248', 'C')
			,	EDI_XML_V2040.DE('0331', '06')
			,	EDI_XML_V2040.DE('0341', '092')
			,	EDI_XML_V2040.DE('0360', @chargeAmount)
			,	EDI_XML_V2040.DE('0352', 'CLAUSE')
			for xml raw ('SEG-LIN'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_Chrysler_ASN.SEG_ITA092(pi())
go

