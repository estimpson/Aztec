
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_N2.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_N2'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_N2
end
go

create function EDI_XML.SEG_N2
(	@dictionaryVersion varchar(25)
,	@entityName varchar(60)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'N2')
			,	EDI_XML.DE(@dictionaryVersion, '0093', @entityName)
			for xml raw ('SEG-N2'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO

select
	EDI_XML.SEG_N2('004010', 'WAREHOUSE OPERATIONS')

select
	*
from
	FxEDI.EDI_DICT.DictionarySegmentContents dsc
	join FxEDI.EDI_DICT.DictionaryElements de
		on de.DictionaryVersion = dsc.DictionaryVersion
		and de.ElementCode = dsc.ElementCode
where
	dsc.DictionaryVersion  = '004010'
	and dsc.Segment = 'N2'