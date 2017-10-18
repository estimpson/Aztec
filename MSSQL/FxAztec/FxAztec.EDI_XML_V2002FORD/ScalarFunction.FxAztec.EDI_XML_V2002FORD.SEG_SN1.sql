
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_SN1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_SN1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_SN1
end
go

create function EDI_XML_V2002FORD.SEG_SN1
(	@identification varchar(20)
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

	set	@xmlOutput = EDI_XML.SEG_SN1('002002FORD', @identification, @units, @unitMeasure, @accum)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_SN1(null, 500, 'EA', 17200)

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode in ('0350', '0355')