SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_HL]
(	@dictionaryVersion varchar(25)
,	@idNumber int
,	@parentIDNumber int
,	@levelCode varchar(3)
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
			,	EDI_XML.DE(@dictionaryVersion, '0628', @idNumber)
			,	EDI_XML.DE(@dictionaryVersion, '0734', @parentIDNumber)
			,	EDI_XML.DE(@dictionaryVersion, '0735', @levelCode)
			for xml raw ('SEG-HL'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
