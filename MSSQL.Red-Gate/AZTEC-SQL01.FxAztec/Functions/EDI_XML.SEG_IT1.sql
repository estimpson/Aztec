SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_IT1]
(	@dictionaryVersion varchar(25)
,	@assignedIdentification varchar(20)
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

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'IT1')
			,	EDI_XML.DE(@dictionaryVersion, '0350', @assignedIdentification)
			,	EDI_XML.DE(@dictionaryVersion, '0358', @quantityInvoiced)
			,	EDI_XML.DE(@dictionaryVersion, '0355', @unit)
			,	EDI_XML.DE(@dictionaryVersion, '0212', @unitPrice)
			,	EDI_XML.DE(@dictionaryVersion, '0639', @unitPriceBasis)
			,	EDI_XML.DE(@dictionaryVersion, '0235', 'PN')
			,	EDI_XML.DE(@dictionaryVersion, '0234', @companyPartNumber)
			,	EDI_XML.DE(@dictionaryVersion, '0235', 'PK')
			,	EDI_XML.DE(@dictionaryVersion, '0234', @packagingDrawing)
			,	EDI_XML.DE(@dictionaryVersion, '0235', 'ZZ')
			,	EDI_XML.DE(@dictionaryVersion, '0234', @mutuallyDefinedIdentifier)
			for xml raw ('SEG-IT1'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
