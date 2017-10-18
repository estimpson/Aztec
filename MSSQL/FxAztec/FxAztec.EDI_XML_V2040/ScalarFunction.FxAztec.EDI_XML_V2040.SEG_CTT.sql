
/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_CTT.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_CTT'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_CTT
end
go

create function EDI_XML_V2040.SEG_CTT
(	@lineCount int
,	@hashTotal int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_CTT('002040', @lineCount, @hashTotal)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_CTT(12, 7619)

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode in ('0354', '0347')