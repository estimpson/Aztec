
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_N4.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_N4'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_N4
end
go

create function EDI_XML.SEG_N4
(	@dictionaryVersion varchar(25)
,	@entityCity varchar(30)
,	@entityState varchar(2)
,	@entityZip varchar(15)
,	@entityCountry varchar(3)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'N4')
			,	EDI_XML.DE(@dictionaryVersion, '0019', @entityCity)
			,	EDI_XML.DE(@dictionaryVersion, '0156', @entityState)
			,	EDI_XML.DE(@dictionaryVersion, '0116', @entityZip)
			,	EDI_XML.DE(@dictionaryVersion, '0026', @entityCountry)
			for xml raw ('SEG-N4'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO

select
	EDI_XML.SEG_N4('004010', 'TOLEDO', 'OH', '43456', 'US')

select
	*
from
	FxEDI.EDI_DICT.DictionarySegmentContents dsc
	join FxEDI.EDI_DICT.DictionaryElements de
		on de.DictionaryVersion = dsc.DictionaryVersion
		and de.ElementCode = dsc.ElementCode
where
	dsc.DictionaryVersion  = '004010'
	and dsc.Segment = 'N4'