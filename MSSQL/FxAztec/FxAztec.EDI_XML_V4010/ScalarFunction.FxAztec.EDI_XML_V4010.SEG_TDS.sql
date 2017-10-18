
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_TDS.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_TDS'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_TDS
end
go

create function EDI_XML_V4010.SEG_TDS
(	@totalMonetaryValue numeric(9,2)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_TDS('004010', @totalMonetaryValue)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_TDS(375.141)
