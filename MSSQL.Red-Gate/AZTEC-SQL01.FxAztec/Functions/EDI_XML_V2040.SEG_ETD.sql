SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_V2040].[SEG_ETD]
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
GO
