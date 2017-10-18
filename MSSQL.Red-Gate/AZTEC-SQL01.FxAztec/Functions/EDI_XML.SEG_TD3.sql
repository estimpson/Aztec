SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_TD3]
(	@dictionaryVersion varchar(25)
,	@equipmentCode varchar(3)
,	@equipmentInitial varchar(12)
,	@equipmentNumber varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'TD3')
			,	EDI_XML.DE(@dictionaryVersion, '0040', @equipmentCode)
			,	EDI_XML.DE(@dictionaryVersion, '0206', @equipmentInitial)
			,	EDI_XML.DE(@dictionaryVersion, '0207', @equipmentNumber)
			for xml raw ('SEG-TD3'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
