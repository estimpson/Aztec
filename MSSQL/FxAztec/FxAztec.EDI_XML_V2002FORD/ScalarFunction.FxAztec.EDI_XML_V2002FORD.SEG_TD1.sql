
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_TD1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_TD1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_TD1
end
go

create function EDI_XML_V2002FORD.SEG_TD1
(	@packageCode varchar(12)
,	@ladingQuantity int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_TD1('002002FORD', @packageCode, @ladingQuantity)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_TD1('CTN90', 39)
