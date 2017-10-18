
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_CTT.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_CTT'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_CTT
end
go

create function EDI_XML.SEG_CTT
(	@dictionaryVersion varchar(25)
,	@lineCount int
,	@hashTotal int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'CTT')
			,	EDI_XML.DE(@dictionaryVersion, '0354', @lineCount)
			,	case when @hashTotal is not null then EDI_XML.DE(@dictionaryVersion, '0347', @hashTotal) end
			for xml raw ('SEG-CTT'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_CTT('002002FORD', 12, 7619)

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode in ('0354', '0347')