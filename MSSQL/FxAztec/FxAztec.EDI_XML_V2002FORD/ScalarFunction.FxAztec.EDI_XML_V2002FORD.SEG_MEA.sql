
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_MEA.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_MEA'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_MEA
end
go

create function EDI_XML_V2002FORD.SEG_MEA
(	@measurementReference varchar(3)
,	@measurementQualifier varchar(3)
,	@measurementValue varchar(8)
,	@measurementUnit varchar(2)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_MEA('002002FORD', @measurementReference, @measurementQualifier, @measurementValue, @measurementUnit)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_MEA('PD', 'G', 680, 'LB')
