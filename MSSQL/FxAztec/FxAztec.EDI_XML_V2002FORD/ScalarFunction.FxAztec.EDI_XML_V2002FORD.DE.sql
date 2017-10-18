
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.DE.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.DE'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.DE
end
go

create function EDI_XML_V2002FORD.DE
(	@elementCode char(4)
,	@value varchar(max)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.DE('002002FORD', @elementCode, @value)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.DE('0353', '00')