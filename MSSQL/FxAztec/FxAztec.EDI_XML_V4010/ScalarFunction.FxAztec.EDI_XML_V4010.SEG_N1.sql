
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_N1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_N1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_N1
end
go

create function EDI_XML_V4010.SEG_N1
(	@entityIdentifierCode varchar(3)
,	@identificationQualifier varchar(3)
,	@identificationCode varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_N1('004010', @entityIdentifierCode, @identificationQualifier, @identificationCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_N1('ST', '92', 'TC05A')
