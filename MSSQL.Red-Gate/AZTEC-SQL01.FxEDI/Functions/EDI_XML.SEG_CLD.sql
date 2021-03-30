SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_CLD]
(	@DictionaryVersion varchar(25)
,	@NumberOfLoads int
,	@NumberOfUnits int
,	@PackagingCode varchar(5)
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
			,	EDI_XML.DE(@dictionaryVersion, '0622', @NumberOfLoads)
			,	EDI_XML.DE(@dictionaryVersion, '0382', @NumberOfUnits)
			,	EDI_XML.DE(@dictionaryVersion, '0103', @PackagingCode)
			for xml raw ('SEG-CLD'), type
		)

--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
