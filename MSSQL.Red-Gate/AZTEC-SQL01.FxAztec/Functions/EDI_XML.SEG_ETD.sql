SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_ETD]
(	@dictionaryVersion varchar(25)
,	@transportationReasonCode varchar(3)
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

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'ETD')
			,	EDI_XML.DE(@dictionaryVersion, '0626', @transportationReasonCode)
			,	EDI_XML.DE(@dictionaryVersion, '0627', @transportationResponsibilityCode)
			,	EDI_XML.DE(@dictionaryVersion, '0128', @referenceNumberQualifier)
			,	EDI_XML.DE(@dictionaryVersion, '0127', @referenceNumber)
			for xml raw ('SEG-ETD'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
