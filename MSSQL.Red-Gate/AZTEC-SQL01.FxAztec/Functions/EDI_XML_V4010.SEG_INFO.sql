SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_V4010].[SEG_INFO]
(	@segmentCode varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_INFO('004010', @segmentCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
