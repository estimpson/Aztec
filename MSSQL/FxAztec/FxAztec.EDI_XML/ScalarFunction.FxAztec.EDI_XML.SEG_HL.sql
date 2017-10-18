
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_HL.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_HL'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_HL
end
go

create function EDI_XML.SEG_HL
(	@dictionaryVersion varchar(25)
,	@idNumber int
,	@parentIDNumber int
,	@levelCode varchar(3)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'HL')
			,	EDI_XML.DE(@dictionaryVersion, '0628', @idNumber)
			,	EDI_XML.DE(@dictionaryVersion, '0734', @parentIDNumber)
			,	EDI_XML.DE(@dictionaryVersion, '0735', @levelCode)
			for xml raw ('SEG-HL'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_HL('002002FORD', 1, null, 'S')
