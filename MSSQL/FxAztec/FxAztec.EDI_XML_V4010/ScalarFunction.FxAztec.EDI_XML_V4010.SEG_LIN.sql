
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_LIN.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_LIN'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_LIN
end
go

create function EDI_XML_V4010.SEG_LIN
(	@assignedIdentification varchar(20)
,	@productQualifier varchar(3)
,	@productNumber varchar(25)
,	@containerQualifier varchar(3)
,	@containerNumber varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V4010.SEG_INFO('LIN')
			,	EDI_XML_V4010.DE('0350', @assignedIdentification)
			,	EDI_XML_V4010.DE('0235', @productQualifier)
			,	EDI_XML_V4010.DE('0234', @productNumber)
			,	EDI_XML_V4010.DE('0235', @containerQualifier)
			,	EDI_XML_V4010.DE('0234', @containerNumber)
			for xml raw ('SEG-LIN'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_LIN('001', 'BP', '123210P05000', 'RC', 'M390')

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