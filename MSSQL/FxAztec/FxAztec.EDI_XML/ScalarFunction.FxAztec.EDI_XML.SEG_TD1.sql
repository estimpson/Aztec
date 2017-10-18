
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_TD1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_TD1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_TD1
end
go

create function EDI_XML.SEG_TD1
(	@dictionaryVersion varchar(25)
,	@packageCode varchar(12)
,	@ladingQuantity int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'TD1')
			,	EDI_XML.DE(@dictionaryVersion, '0103', @packageCode)
			,	EDI_XML.DE(@dictionaryVersion, '0080', @ladingQuantity)
			for xml raw ('SEG-TD1'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_TD1('002002FORD', 'CTN90', 39)
