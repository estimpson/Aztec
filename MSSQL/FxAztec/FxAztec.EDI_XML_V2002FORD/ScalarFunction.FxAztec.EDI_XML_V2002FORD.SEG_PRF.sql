
/*
Create ScalarFunction.FxAztec.EDI_XML_V2002FORD.SEG_PRF.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML_V2002FORD.SEG_PRF'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML_V2002FORD.SEG_PRF
end
go

create function EDI_XML_V2002FORD.SEG_PRF
(	@poNumber varchar(22)
)
returns xml
as
begin
--- <Body>
	declare
		@xmlOutput xml

	set	@xmlOutput = EDI_XML.SEG_PRF('002002FORD', @poNumber)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML_V2002FORD.SEG_PRF('ND0228')

select
	*
from
	fxEDI.EDI_DICT.DictionaryElements de
where
	de.ElementCode = '0324'