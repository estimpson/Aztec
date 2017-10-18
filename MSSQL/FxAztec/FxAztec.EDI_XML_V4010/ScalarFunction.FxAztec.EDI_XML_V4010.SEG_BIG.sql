
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_BIG.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_BIG'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_BIG
end
go

create function EDI_XML_V4010.SEG_BIG
(	@invoiceDate date
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
				EDI_XML.SEG_INFO('004010', 'BIG')
			,	EDI_XML.DE('004010', '0373', EDI_XML.FormatDate('004010', @invoiceDate))
			,	EDI_XML.DE('004010', '0076', @invoiceNumber)
			for xml raw ('SEG-BIG'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_BIG(getdate(), '01350')
