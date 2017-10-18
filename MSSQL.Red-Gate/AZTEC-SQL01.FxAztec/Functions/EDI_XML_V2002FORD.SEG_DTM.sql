SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_V2002FORD].[SEG_DTM]
(	@dateCode varchar(3)
,	@dateTime datetime
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_DTM('002002FORD', @dateCode, @dateTime)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
