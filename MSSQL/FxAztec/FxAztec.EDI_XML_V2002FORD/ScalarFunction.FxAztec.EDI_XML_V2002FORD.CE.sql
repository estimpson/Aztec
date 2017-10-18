
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.CE.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.CE'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.CE
end
go

create function EDI_XML_V2002FORD.CE
(	@elementCode char(4)
,	@de xml
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.CE('002002FORD', @elementCode, @de)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.CE('C001', EDI_XML_V2002FORD.DE('355', 'LB'))
