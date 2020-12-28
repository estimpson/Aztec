SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_V4010].[SEG_N2]
(	@entityName varchar(60)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_N2('004010', @entityName)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
