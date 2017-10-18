
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_HL.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_HL'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_HL
end
go

create function EDI_XML_V2002FORD.SEG_HL
(	@idNumber int
,	@parentIDNumber int
,	@levelCode varchar(3)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_HL('002002FORD', @idNumber, @parentIDNumber, @levelCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_HL(1, null, 'S')
