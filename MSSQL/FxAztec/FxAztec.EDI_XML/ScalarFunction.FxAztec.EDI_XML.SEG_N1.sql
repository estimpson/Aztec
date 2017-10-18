
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_N1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_N1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_N1
end
go

create function EDI_XML.SEG_N1
(	@dictionaryVersion varchar(25)
,	@entityIdentifierCode varchar(3)
,	@identificationQualifier varchar(3)
,	@identificationCode varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'N1')
			,	EDI_XML.DE(@dictionaryVersion, '0098', @entityIdentifierCode)
			,	EDI_XML.DE(@dictionaryVersion, '0093', null)
			,	EDI_XML.DE(@dictionaryVersion, '0066', @identificationQualifier)
			,	EDI_XML.DE(@dictionaryVersion, '0067', @identificationCode)
			for xml raw ('SEG-N1'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_N1('002002FORD', 'ST', '92', 'TC05A')
