SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_V2040].[SEG_MEA]
(	@measurementReference varchar(3)
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
				EDI_XML_V2040.SEG_INFO('MEA')
			,	EDI_XML_V2040.DE('0737', @measurementReference)
			,	EDI_XML_V2040.DE('0738', @measurementQualifier)
			,	EDI_XML_V2040.DE('0739', @measurementValue)
			,	EDI_XML_V2040.CE('C001', EDI_XML_V2040.DE('355', @measurementUnit))
			for xml raw ('SEG-MEA'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
