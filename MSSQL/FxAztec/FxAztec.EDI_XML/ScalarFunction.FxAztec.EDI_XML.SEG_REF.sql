
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_REF.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_REF'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_REF
end
go

create function EDI_XML.SEG_REF
(	@dictionaryVersion varchar(25)
,	@refenceQualifier varchar(3)
,	@refenceNumber varchar(30)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'REF')
			,	EDI_XML.DE(@dictionaryVersion, '0128', @refenceQualifier)
			,	EDI_XML.DE(@dictionaryVersion, '0127', @refenceNumber)
			for xml raw ('SEG-REF'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_REF('002002FORD', 'BM', '797120')

select
	EDI_XML.SEG_REF('002002FORD', 'PK', '75964')
