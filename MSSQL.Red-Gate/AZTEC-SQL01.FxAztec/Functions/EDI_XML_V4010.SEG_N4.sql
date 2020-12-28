SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_V4010].[SEG_N4]
(	@entityCity varchar(30)
,	@entityState varchar(2)
,	@entityZip varchar(15)
,	@entityCountry varchar(3)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_N4('004010', @entityCity, @entityState, @entityZip, @entityCountry)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
