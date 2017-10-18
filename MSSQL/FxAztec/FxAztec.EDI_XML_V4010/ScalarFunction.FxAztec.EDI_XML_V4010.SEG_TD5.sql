
/*
Create ScalarFunction.FxAztec.EDI_XML_V4010.SEG_TD5.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V4010.SEG_TD5'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V4010.SEG_TD5
end
go

create function EDI_XML_V4010.SEG_TD5
(	@routingSequenceCode varchar(3)
,	@identificaitonQualifier varchar(3)
,	@identificaitonCode varchar(12)
,	@transMethodCode varchar(3)
,	@locationQualifier varchar(3)
,	@locationIdentifier varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_TD5('004010', @routingSequenceCode, @identificaitonQualifier, @identificaitonCode, @transMethodCode, @locationQualifier, @locationIdentifier)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V4010.SEG_TD5('B', 2, 'RYDD', 'M', null, null)

select
	EDI_XML_V4010.SEG_TD5('B', 2, 'PSKL', 'C', 'PP', 'PC07A')
