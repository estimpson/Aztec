
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_LIN.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_LIN'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_LIN
end
go

create function EDI_XML_V2002FORD.SEG_LIN
(	@productQualifier varchar(3)
,	@productNumber varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_LIN('002002FORD', @productQualifier, @productNumber)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_LIN('BP', 'FL1W 4C000 FB')

select
	*
from
	fxEDI.EDI_DICT.DictionarySegmentContents dsc
where
	dsc.Segment = 'LIN'

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode = '0350'