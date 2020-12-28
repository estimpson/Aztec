SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_N4]
(	@dictionaryVersion varchar(25)
,	@entityCity varchar(30)
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

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'N4')
			,	EDI_XML.DE(@dictionaryVersion, '0019', @entityCity)
			,	EDI_XML.DE(@dictionaryVersion, '0156', @entityState)
			,	EDI_XML.DE(@dictionaryVersion, '0116', @entityZip)
			,	EDI_XML.DE(@dictionaryVersion, '0026', @entityCountry)
			for xml raw ('SEG-N4'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
