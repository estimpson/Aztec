
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_PRF.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_PRF'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_PRF
end
go

create function EDI_XML.SEG_PRF
(	@dictionaryVersion varchar(25)
,	@poNumber varchar(22)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput =
		(	select
				EDI_XML.SEG_INFO(@dictionaryVersion, 'PRF')
			,	EDI_XML.DE(@dictionaryVersion, '0324', @poNumber)
			for xml raw ('SEG-PRF'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.SEG_PRF('002002FORD', 'ND0228')

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode = '0324'