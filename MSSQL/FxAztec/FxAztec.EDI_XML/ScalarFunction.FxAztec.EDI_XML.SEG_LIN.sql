
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_LIN.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_LIN'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_LIN
end
go

create function EDI_XML.SEG_LIN
(	@dictionaryVersion varchar(25)
,	@productQualifier varchar(3)
,	@productNumber varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'LIN')
			,	EDI_XML.DE(@dictionaryVersion, '0235', @productQualifier)
			,	EDI_XML.DE(@dictionaryVersion, '0234', @productNumber)
			for xml raw ('SEG-LIN'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_LIN('002002FORD', 'BP', 'FL1W 4C000 FB')

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
	de.ElementCode = '0234'