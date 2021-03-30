SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_BSN]
(	@DictionaryVersion varchar(25)
,	@TransactionSetPurposeCode char(2)
,	@ShipmentId varchar(30)
,	@Date datetime
,	@Time datetime
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
			,	EDI_XML.DE(@dictionaryVersion, '0353', @TransactionSetPurposeCode)
			,	EDI_XML.DE(@dictionaryVersion, '0396', @ShipmentId)
			,	EDI_XML.DE(@dictionaryVersion, '0373', EDI_XML.FormatDate(@dictionaryVersion,@Date))
			,	EDI_XML.DE(@dictionaryVersion, '0337', EDI_XML.FormatTime(@dictionaryVersion,@Time))
			for xml raw ('SEG-BSN'), type
		)

--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
