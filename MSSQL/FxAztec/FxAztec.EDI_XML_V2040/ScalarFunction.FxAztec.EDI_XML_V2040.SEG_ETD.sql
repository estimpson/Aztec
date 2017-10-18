
/*
Create ScalarFunction.FxAztec.EDI_XML_V2040.SEG_ETD.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2040.SEG_ETD'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2040.SEG_ETD
end
go

create function EDI_XML_V2040.SEG_ETD
(	@transportationReasonCode varchar(3)
,	@transportationResponsibilityCode varchar(3)
,	@referenceNumberQualifier varchar(3)
,	@referenceNumber varchar(30)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_ETD ('002040', @transportationReasonCode, @transportationResponsibilityCode, @referenceNumberQualifier, @referenceNumber)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2040.SEG_ETD('ZZ', 'A', 'AE', 'AETCNumber')
