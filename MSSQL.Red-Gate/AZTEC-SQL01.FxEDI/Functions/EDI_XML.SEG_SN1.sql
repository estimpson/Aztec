SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_SN1]
(	@DictionaryVersion varchar(25)
,	@AssignedId varchar(20)
,	@Quantity int
,	@Unit char(2)
,	@Accum int
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'SN1')
			,	EDI_XML.DE(@dictionaryVersion, '0350', @AssignedId)
			,	EDI_XML.DE(@dictionaryVersion, '0382', @Quantity)
			,	EDI_XML.DE(@dictionaryVersion, '0355', @Unit)
			,	case when @Accum > 0 then EDI_XML.DE(@dictionaryVersion, '0646', @Accum) end
			for xml raw ('SEG-SN1'), type
		)

--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
