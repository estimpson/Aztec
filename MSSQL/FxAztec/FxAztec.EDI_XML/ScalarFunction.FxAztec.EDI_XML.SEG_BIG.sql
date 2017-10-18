
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_BIG.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_BIG'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_BIG
end
go

create function EDI_XML.SEG_BIG
(	@dictionaryVersion varchar(25)
,	@invoiceDate date
,	@invoiceNumber varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'BIG')
			,	EDI_XML.DE(@dictionaryVersion, '0373', EDI_XML.FormatDate(@dictionaryVersion, @invoiceDate))
			,	EDI_XML.DE(@dictionaryVersion, '0076', @invoiceNumber)
			for xml raw ('SEG-BIG'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_BIG('002002FORD', getdate(), '01350')
