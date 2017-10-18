SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_LIN]
(	@dictionaryVersion varchar(25)
,	@productQualifier varchar(3)
,	@productNumber varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'LIN')
			,	EDI_XML.DE(@dictionaryVersion, '0235', @productQualifier)
			,	EDI_XML.DE(@dictionaryVersion, '0234', @productNumber)
			for xml raw ('SEG-LIN'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
