SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_V2040].[SEG_DTM]
(	@dateCode varchar(3)
,	@dateTime datetime
,	@timeZoneCode varchar(3)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML_V2040.SEG_INFO('DTM')
			,	EDI_XML_V2040.DE('0374', @dateCode)
			,	EDI_XML_V2040.DE('0373', EDI_XML.FormatDate('002040', @dateTime))
			,	EDI_XML_V2040.DE('0337', EDI_XML.FormatTime('002040', @dateTime))
			,	EDI_XML_V2040.DE('0623', @timeZoneCode)
			for xml raw ('SEG-DTM'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
