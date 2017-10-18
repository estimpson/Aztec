SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_SN1]
(	@dictionaryVersion varchar(25)
,	@identification varchar(20)
,	@units int
,	@unitMeasure char(2)
,	@accum int
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
			,	EDI_XML.DE(@dictionaryVersion, '0350', @identification)
			,	EDI_XML.DE(@dictionaryVersion, '0382', @units)
			,	EDI_XML.DE(@dictionaryVersion, '0355', @unitMeasure)
			,	case when @accum > 0 then EDI_XML.DE(@dictionaryVersion, '0646', @accum) end
			for xml raw ('SEG-SN1'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
