SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_CLD]
(	@dictionaryVersion varchar(25)
,	@loads int
,	@units int
,	@packageCode varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'CLD')
			,	EDI_XML.DE(@dictionaryVersion, '0622', @loads)
			,	EDI_XML.DE(@dictionaryVersion, '0382', @units)
			,	EDI_XML.DE(@dictionaryVersion, '0103', @packageCode)
			for xml raw ('SEG-CLD'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
