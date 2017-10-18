SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML_Toyota_Invoice].[SEG_DTM]
(	@dateCode varchar(3)
,	@date date
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO('004010', 'DTM')
			,	EDI_XML.DE('004010', '0374', @dateCode)
			,	EDI_XML.DE('004010', '0373', EDI_XML.FormatDate('004010',@date))
			for xml raw ('SEG-DTM'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
