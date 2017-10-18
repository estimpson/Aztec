
/*
Create ScalarFunction.FxAztec.EDI_XML.SEG_TDS.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.SEG_TDS'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.SEG_TDS
end
go

create function EDI_XML.SEG_TDS
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
go

select
	EDI_XML.SEG_TDS('002002FORD', 375.141)
