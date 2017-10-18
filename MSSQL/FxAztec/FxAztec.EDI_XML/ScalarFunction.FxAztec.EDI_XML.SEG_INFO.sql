
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_INFO.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_INFO'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_INFO
end
go

create function EDI_XML.SEG_INFO
(	@dictionaryVersion varchar(25)
,	@segmentCode varchar(25)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
	/*	CE */
		(	select
				code = dsc.Code
			,	name = dsc.Description
			from
				FxEDI.EDI_DICT.DictionarySegmentCodes dsc
			where
				dsc.DictionaryVersion = @dictionaryVersion
				and dsc.Code = @segmentCode
			for xml raw ('SEG-INFO'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_INFO ('002002FORD', 'BSN')