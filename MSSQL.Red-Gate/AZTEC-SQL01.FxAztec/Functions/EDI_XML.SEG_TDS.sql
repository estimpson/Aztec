SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_TDS]
(	@dictionaryVersion varchar(25)
,	@totalMonetaryValue numeric(9,2)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'TDS')
			,	EDI_XML.DE(@dictionaryVersion, '0610', @totalMonetaryValue)
			for xml raw ('SEG-TDS'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
