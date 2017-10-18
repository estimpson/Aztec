
/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_HL.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_HL'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_HL
end
go

create function EDI_XML_V2040.SEG_HL
(	@idNumber int
,	@parentIDNumber int
,	@levelCode varchar(3)
,	@childCode int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V2040.SEG_INFO('HL')
			,	EDI_XML_V2040.DE('0628', @idNumber)
			,	EDI_XML_V2040.DE('0734', @parentIDNumber)
			,	EDI_XML_V2040.DE('0735', @levelCode)
			,	EDI_XML_V2040.DE('0736', @childCode)
			for xml raw ('SEG-HL'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_HL(1, null, 'S', 1)
