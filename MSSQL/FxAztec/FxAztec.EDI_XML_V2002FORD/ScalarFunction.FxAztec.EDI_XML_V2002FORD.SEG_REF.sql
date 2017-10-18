
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_REF.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_REF'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_REF
end
go

create function EDI_XML_V2002FORD.SEG_REF
(	@refenceQualifier varchar(3)
,	@refenceNumber varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_REF('002002FORD', @refenceQualifier, @refenceNumber)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_REF('BM', '797120')

select
	EDI_XML_V2002FORD.SEG_REF('PK', '75964')
