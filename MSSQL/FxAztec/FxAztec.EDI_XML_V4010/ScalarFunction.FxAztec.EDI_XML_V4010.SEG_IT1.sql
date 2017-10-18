
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_IT1.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_IT1'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_IT1
end
go

create function EDI_XML_V4010.SEG_IT1
(	@assignedIdentification varchar(20)
,	@quantityInvoiced int
,	@unit char(2)
,	@unitPrice numeric(9,4)
,	@unitPriceBasis char(2)
,	@companyPartNumber varchar(40)
,	@packagingDrawing varchar(40)
,	@mutuallyDefinedIdentifier varchar(40)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_IT1
		(	'004010'
		,	@assignedIdentification
		,	@quantityInvoiced
		,	@unit
		,	@unitPrice
		,	@unitPriceBasis
		,	@companyPartNumber
		,	@packagingDrawing
		,	@mutuallyDefinedIdentifier
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_IT1('M390', 36, 'EA', 10.42061, 'QT', '123210P05000', '1', 'N1')