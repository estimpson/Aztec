
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_N3.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_N3'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_N3
end
go

create function EDI_XML.SEG_N3
(	@dictionaryVersion varchar(25)
,	@entityAddress varchar(55)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'N3')
			,	EDI_XML.DE(@dictionaryVersion, '0166', @entityAddress)
			for xml raw ('SEG-N3'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO

select
	EDI_XML.SEG_N3('004010', '1234 ENTERPRISE BLVD')

select
	*
from
	FxEDI.EDI_DICT.DictionarySegmentContents dsc
	join FxEDI.EDI_DICT.DictionaryElements de
		on de.DictionaryVersion = dsc.DictionaryVersion
		and de.ElementCode = dsc.ElementCode
where
	dsc.DictionaryVersion  = '004010'
	and dsc.Segment = 'N3'