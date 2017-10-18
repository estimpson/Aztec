SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_BSN]
(	@dictionaryVersion varchar(25)
,	@purposeCode char(2)
,	@shipperID varchar(12)
,	@shipDate date
,	@shipTime time
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'BSN')
			,	EDI_XML.DE(@dictionaryVersion, '0353', @purposeCode)
			,	EDI_XML.DE(@dictionaryVersion, '0396', @shipperID)
			,	EDI_XML.DE(@dictionaryVersion, '0373', EDI_XML.FormatDate(@dictionaryVersion,@shipDate))
			,	EDI_XML.DE(@dictionaryVersion, '0337', EDI_XML.FormatTime(@dictionaryVersion,@shipTime))
			for xml raw ('SEG-BSN'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
