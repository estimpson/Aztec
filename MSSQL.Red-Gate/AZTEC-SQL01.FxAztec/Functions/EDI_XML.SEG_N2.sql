SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_N2]
(	@dictionaryVersion varchar(25)
,	@entityName varchar(60)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'N2')
			,	EDI_XML.DE(@dictionaryVersion, '0093', @entityName)
			for xml raw ('SEG-N2'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
