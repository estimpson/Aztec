SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_V4010].[SEG_IT1]
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
GO
