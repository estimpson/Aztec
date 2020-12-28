
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_N2.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_N2'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_N2
end
go

create function EDI_XML_V4010.SEG_N2
(	@entityName varchar(60)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_N2('004010', @entityName)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_N2 ('WAREHOUSE OPERATIONS')