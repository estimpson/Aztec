SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI_XML].[SEG_TD5]
(	@DictionaryVersion varchar(25)
,	@RoutingSequenceCode varchar(2)
,	@IdQualifierCode varchar(2)
,	@IdCode varchar(80)
,	@TransCode varchar(2)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'TD5')
			,	EDI_XML.DE(@dictionaryVersion, '0133', @RoutingSequenceCode)
			,	EDI_XML.DE(@dictionaryVersion, '0066', @IdQualifierCode)
			,	EDI_XML.DE(@dictionaryVersion, '0067', @IdCode)
			,	EDI_XML.DE(@dictionaryVersion, '0091', @TransCode)
			for xml raw ('SEG-TD5'), type
		)

--- </Body>

---	<Return>
	return
		@xmlOutput
end
GO
