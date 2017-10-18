
/*
Create ScalarFunction.FxAztec.EDI_XML_Toyota_Invoice.SEG_DTM.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_Toyota_Invoice.SEG_DTM'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_Toyota_Invoice.SEG_DTM
end
go

create function EDI_XML_Toyota_Invoice.SEG_DTM
(	@dateCode varchar(3)
,	@date date
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO('004010', 'DTM')
			,	EDI_XML.DE('004010', '0374', @dateCode)
			,	EDI_XML.DE('004010', '0373', EDI_XML.FormatDate('004010',@date))
			for xml raw ('SEG-DTM'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_Toyota_Invoice.SEG_DTM('050', '2016-04-28 10:18')
