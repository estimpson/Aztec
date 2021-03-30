SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_TD1]
(	@dictionaryVersion varchar(25)
,	@packageCode varchar(12)
,	@ladingQuantity int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'TD1')
			,	EDI_XML.DE(@dictionaryVersion, '0103', @packageCode)
			,	EDI_XML.DE(@dictionaryVersion, '0080', @ladingQuantity)
			for xml raw ('SEG-TD1'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
