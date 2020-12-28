SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_V4010].[SEG_N3]
(	@entityAddress varchar(55)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_N3('004010', @entityAddress)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
