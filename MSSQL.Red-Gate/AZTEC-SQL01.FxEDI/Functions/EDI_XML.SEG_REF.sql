SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_REF]
(	@dictionaryVersion varchar(25)
,	@refenceNumberQualifier varchar(3)
,	@refenceNumber varchar(30) = null
,	@description varchar(80) = null
,	@referenceIdentifier xml = null
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
			,	EDI_XML.DE(@dictionaryVersion, '0128', @refenceNumberQualifier)
			,	case when @refenceNumber is not null then EDI_XML.DE(@dictionaryVersion, '0127', @refenceNumber) end
			,	case when @description is not null then EDI_XML.DE(@dictionaryVersion, '0352', @description) end
			,	@referenceIdentifier
			for xml raw ('SEG-REF'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
