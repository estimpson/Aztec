
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_DTM.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_DTM'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_DTM
end
go

create function EDI_XML_V2002FORD.SEG_DTM
(	@dateCode varchar(3)
,	@dateTime datetime
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_DTM('002002FORD', @dateCode, @dateTime)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_DTM('011', '2016-04-28 10:18')
