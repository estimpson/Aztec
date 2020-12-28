
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_N4.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_N4'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_N4
end
go

create function EDI_XML_V4010.SEG_N4
(	@entityCity varchar(30)
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

	set	@xmlOutput = EDI_XML.SEG_N4('004010', @entityCity, @entityState, @entityZip, @entityCountry)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_N4 ('TOLEDO', 'OH', '43456', 'US')