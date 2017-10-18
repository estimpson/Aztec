
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_BSN.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_BSN'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_BSN
end
go

create function EDI_XML_V2002FORD.SEG_BSN
(	@purposeCode char(2)
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

	set	@xmlOutput = EDI_XML.SEG_BSN('002002FORD', @purposeCode, @shipperID, @shipDate, @shipTime)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_BSN('00', 75964, '2016-04-29', '10:11')
