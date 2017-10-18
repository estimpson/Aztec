SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_V2040].[SEG_TD5]
(	@routingSequenceCode varchar(3)
,	@identificaitonQualifier varchar(3)
,	@identificaitonCode varchar(12)
,	@transMethodCode varchar(3)
,	@locationQualifier varchar(3)
,	@locationIdentifier varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_TD5('002040', @routingSequenceCode, @identificaitonQualifier, @identificaitonCode, @transMethodCode, @locationQualifier, @locationIdentifier)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
