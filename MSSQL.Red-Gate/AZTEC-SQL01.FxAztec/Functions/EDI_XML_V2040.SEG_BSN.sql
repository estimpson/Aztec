SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_V2040].[SEG_BSN]
(	@purposeCode char(2)
,	@shipperID varchar(12)
,	@shipDate date
,	@shipTime time
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_BSN('002040', @purposeCode, @shipperID, @shipDate, @shipTime)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
