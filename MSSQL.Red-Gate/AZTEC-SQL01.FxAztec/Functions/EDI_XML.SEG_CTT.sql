SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_CTT]
(	@dictionaryVersion varchar(25)
,	@lineCount int
,	@hashTotal int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'CTT')
			,	EDI_XML.DE(@dictionaryVersion, '0354', @lineCount)
			,	case when @hashTotal is not null then EDI_XML.DE(@dictionaryVersion, '0347', @hashTotal) end
			for xml raw ('SEG-CTT'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
