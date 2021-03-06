
/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_DTM.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_DTM'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_DTM
end
go

create function EDI_XML_V2040.SEG_DTM
(	@dateCode varchar(3)
,	@dateTime datetime
,	@timeZoneCode varchar(3)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V2040.SEG_INFO('DTM')
			,	EDI_XML_V2040.DE('0374', @dateCode)
			,	EDI_XML_V2040.DE('0373', EDI_XML.FormatDate('002040', @dateTime))
			,	EDI_XML_V2040.DE('0337', EDI_XML.FormatTime('002040', @dateTime))
			,	EDI_XML_V2040.DE('0623', @timeZoneCode)
			for xml raw ('SEG-DTM'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_DTM('011', '2016-04-28 10:18', 'ED')
