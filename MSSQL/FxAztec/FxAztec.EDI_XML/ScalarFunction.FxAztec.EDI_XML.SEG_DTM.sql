
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_DTM.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_DTM'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_DTM
end
go

create function EDI_XML.SEG_DTM
(	@dictionaryVersion varchar(25)
,	@dateCode varchar(3)
,	@dateTime datetime
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'DTM')
			,	EDI_XML.DE(@dictionaryVersion, '0374', @dateCode)
			,	EDI_XML.DE(@dictionaryVersion, '0373', EDI_XML.FormatDate(@dictionaryVersion,@dateTime))
			,	EDI_XML.DE(@dictionaryVersion, '0337', EDI_XML.FormatTime(@dictionaryVersion,@dateTime))
			for xml raw ('SEG-DTM'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_DTM('002002FORD', '011', '2016-04-28 10:18')
