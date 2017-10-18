
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_BSN.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_BSN'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_BSN
end
go

create function EDI_XML.SEG_BSN
(	@dictionaryVersion varchar(25)
,	@purposeCode char(2)
,	@shipperID varchar(12)
,	@shipDate date
,	@shipTime time
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'BSN')
			,	EDI_XML.DE(@dictionaryVersion, '0353', @purposeCode)
			,	EDI_XML.DE(@dictionaryVersion, '0396', @shipperID)
			,	EDI_XML.DE(@dictionaryVersion, '0373', EDI_XML.FormatDate(@dictionaryVersion,@shipDate))
			,	EDI_XML.DE(@dictionaryVersion, '0337', EDI_XML.FormatTime(@dictionaryVersion,@shipTime))
			for xml raw ('SEG-BSN'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_BSN('002002FORD', '00', 75964, '2016-04-29', '10:11')
