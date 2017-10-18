SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_V2002FORD].[SEG_CLD]
(	@loads int
,	@units int
,	@packageCode varchar(12)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_CLD('002002FORD', @loads, @units, @packageCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
