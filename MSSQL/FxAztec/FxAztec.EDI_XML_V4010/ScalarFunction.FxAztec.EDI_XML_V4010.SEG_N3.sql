
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_N3.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_N3'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_N3
end
go

create function EDI_XML_V4010.SEG_N3
(	@entityAddress varchar(55)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_N3('004010', @entityAddress)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_N3 ('1234 ENTERPRISE BLVD')