
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_SN1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_SN1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_SN1
end
go

create function EDI_XML_V4010.SEG_SN1
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

	set	@xmlOutput = EDI_XML.SEG_SN1('004010', @identification, @units, @unitMeasure, @accum)
--- </Body>

---	<Return>
	return
		@xmlOutput
end

GO

