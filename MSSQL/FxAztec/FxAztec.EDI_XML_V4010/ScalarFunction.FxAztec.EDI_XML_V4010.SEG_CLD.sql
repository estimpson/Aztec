
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_CLD.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_CLD'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_CLD
end
go

create function EDI_XML_V4010.SEG_CLD
(	@loads int
,	@units int
,	@packageCode varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_CLD('004010', @loads, @units, @packageCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_CLD(5, 100, 'CTN90')
