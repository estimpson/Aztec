
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_SN1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_SN1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_SN1
end
go

create function EDI_XML.SEG_SN1
(	@dictionaryVersion varchar(25)
,	@identification varchar(20)
,	@units int
,	@unitMeasure char(2)
,	@accum int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'SN1')
			,	EDI_XML.DE(@dictionaryVersion, '0350', @identification)
			,	EDI_XML.DE(@dictionaryVersion, '0382', @units)
			,	EDI_XML.DE(@dictionaryVersion, '0355', @unitMeasure)
			,	case when @accum > 0 then EDI_XML.DE(@dictionaryVersion, '0646', @accum) end
			for xml raw ('SEG-SN1'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_SN1('002002FORD', null, 500, 'EA', 17200)

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode in ('0350', '0355')