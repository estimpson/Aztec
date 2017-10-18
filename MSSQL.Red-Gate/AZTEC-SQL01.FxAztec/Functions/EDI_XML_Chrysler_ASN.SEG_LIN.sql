SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_Chrysler_ASN].[SEG_LIN]
(	@productQualifier varchar(3)
,	@productNumber varchar(25)
,	@engineeringChangeQualifier varchar(3)
,	@engineeringChangeNumber varchar(25)
,	@returnableContainerQualifier varchar(3)
,	@returnableContainerNumber varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V2040.SEG_INFO('LIN')
			,	EDI_XML_V2040.DE('0235', @productQualifier)
			,	EDI_XML_V2040.DE('0234', @productNumber)
			,	case when @engineeringChangeNumber > '' then EDI_XML_V2040.DE('0235', @engineeringChangeQualifier) end
			,	case when @engineeringChangeNumber > '' then EDI_XML_V2040.DE('0234', @engineeringChangeNumber) end
			,	EDI_XML_V2040.DE('0235', @returnableContainerQualifier)
			,	EDI_XML_V2040.DE('0234', @returnableContainerNumber)
			for xml raw ('SEG-LIN'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
