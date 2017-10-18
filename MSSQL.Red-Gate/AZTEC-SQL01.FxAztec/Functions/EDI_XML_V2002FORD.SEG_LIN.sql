SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_V2002FORD].[SEG_LIN]
(	@productQualifier varchar(3)
,	@productNumber varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_LIN('002002FORD', @productQualifier, @productNumber)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
