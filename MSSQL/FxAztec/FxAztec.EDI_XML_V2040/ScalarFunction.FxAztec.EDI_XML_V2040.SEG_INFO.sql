
/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_INFO.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_INFO'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_INFO
end
go

create function EDI_XML_V2040.SEG_INFO
(	@segmentCode varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_INFO('002040', @segmentCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_INFO ('BSN')