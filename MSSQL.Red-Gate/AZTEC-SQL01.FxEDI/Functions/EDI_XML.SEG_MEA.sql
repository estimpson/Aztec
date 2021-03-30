SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_MEA]
(	@dictionaryVersion varchar(25)
,	@measurementReference varchar(3)
,	@measurementQualifier varchar(3)
,	@measurementValue varchar(8)
,	@measurementUnit varchar(2)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'MEA')
			,	EDI_XML.DE(@dictionaryVersion, '0737', @measurementReference)
			,	EDI_XML.DE(@dictionaryVersion, '0738', @measurementQualifier)
			,	EDI_XML.DE(@dictionaryVersion, '0739', @measurementValue)
			,	EDI_XML.DE(@dictionaryVersion, '0355', @measurementUnit)
			for xml raw ('SEG-MEA'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
