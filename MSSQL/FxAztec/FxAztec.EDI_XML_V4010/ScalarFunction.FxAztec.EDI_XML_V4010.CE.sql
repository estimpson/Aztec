
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.CE.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.CE'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.CE
end
go

create function EDI_XML_V4010.CE
(	@elementCode char(4)
,	@de xml
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.CE('004010', @elementCode, @de)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.CE('C001', EDI_XML_V4010.DE('355', 'LB'))
