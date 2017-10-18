SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_V4010].[SEG_HL]
(	@idNumber int
,	@parentIDNumber int
,	@levelCode varchar(3)
,	@childCode int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V4010.SEG_INFO('HL')
			,	EDI_XML_V4010.DE('0628', @idNumber)
			,	EDI_XML_V4010.DE('0734', @parentIDNumber)
			,	EDI_XML_V4010.DE('0735', @levelCode)
			,	EDI_XML_V4010.DE('0736', @childCode)
			for xml raw ('SEG-HL'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
