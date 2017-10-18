
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_REF.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_REF'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_REF
end
go

create function EDI_XML_V4010.SEG_REF
(	@refenceQualifier varchar(3)
,	@refenceNumber varchar(30)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_REF('004010', @refenceQualifier, @refenceNumber)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_REF('BM', '797120')

select
	EDI_XML_V4010.SEG_REF('PK', '75964')

select
	*
from
	FxEDI.EDI_DICT.DictionarySegmentContents dsc
where
	dsc.Segment = 'REF'
	and dsc.DictionaryVersion = '004010'

select
	*
from
	FxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode = '0127'
	and de.DictionaryVersion = '004010'