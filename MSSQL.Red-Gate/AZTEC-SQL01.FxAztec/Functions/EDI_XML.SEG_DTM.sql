SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_DTM]
(	@dictionaryVersion varchar(25)
,	@dateCode varchar(3)
,	@dateTime datetime
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'DTM')
			,	EDI_XML.DE(@dictionaryVersion, '0374', @dateCode)
			,	EDI_XML.DE(@dictionaryVersion, '0373', EDI_XML.FormatDate(@dictionaryVersion,@dateTime))
			,	EDI_XML.DE(@dictionaryVersion, '0337', EDI_XML.FormatTime(@dictionaryVersion,@dateTime))
			for xml raw ('SEG-DTM'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
