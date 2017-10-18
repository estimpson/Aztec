SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_REF]
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
GO
