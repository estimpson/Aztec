SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_HL]
(	@DictionaryVersion varchar(25)
,	@HierarchicalID int
,	@HierarchicalParentID int
,	@HierarchicalLevelCode varchar(2)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'HL')
			,	EDI_XML.DE(@dictionaryVersion, '0628', @HierarchicalID)
			,	EDI_XML.DE(@dictionaryVersion, '0734', @HierarchicalParentID)
			,	EDI_XML.DE(@dictionaryVersion, '0735', @HierarchicalLevelCode)
			for xml raw ('SEG-HL'), type
		)

--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
