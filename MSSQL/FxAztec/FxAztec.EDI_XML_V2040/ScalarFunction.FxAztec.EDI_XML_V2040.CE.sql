
/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.CE.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.CE'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.CE
end
go

create function EDI_XML_V2040.CE
(	@elementCode char(4)
,	@de xml
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.CE('002040', @elementCode, @de)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.CE('C001', EDI_XML_V2040.DE('355', 'LB'))

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode = 'C001'