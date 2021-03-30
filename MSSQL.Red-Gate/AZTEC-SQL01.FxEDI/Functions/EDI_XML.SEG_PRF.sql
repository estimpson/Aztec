SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_PRF]
(	@DictionaryVersion varchar(25)
,	@PurchaseOrder varchar(22)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'PRF')
			,	EDI_XML.DE(@dictionaryVersion, '0324', @PurchaseOrder)
			for xml raw ('SEG-PRF'), type
		)

--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
