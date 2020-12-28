SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_N3]
(	@dictionaryVersion varchar(25)
,	@entityAddress varchar(55)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'N3')
			,	EDI_XML.DE(@dictionaryVersion, '0166', @entityAddress)
			for xml raw ('SEG-N3'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
