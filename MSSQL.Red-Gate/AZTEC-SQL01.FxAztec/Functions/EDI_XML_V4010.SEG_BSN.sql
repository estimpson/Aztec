SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_V4010].[SEG_BSN]
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

	set	@xmlOutput = EDI_XML.SEG_BSN('004010', @purposeCode, @shipperID, @shipDate, @shipTime)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
