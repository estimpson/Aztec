SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_V2002FORD].[SEG_HL]
(	@idNumber int
,	@parentIDNumber int
,	@levelCode varchar(3)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_HL('002002FORD', @idNumber, @parentIDNumber, @levelCode)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
