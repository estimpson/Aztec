
/*
Create ScalarFunction.FxAztec.EDI_XML.LOOP_INFO.sql
*/

use FxAztec
go

if	objectproperty(object_id('EDI_XML.LOOP_INFO'), 'IsScalarFunction') = 1 begin
	drop function EDI_XML.LOOP_INFO
end
go

create function EDI_XML.LOOP_INFO
(	@loopCode varchar(25)
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
				name = @loopCode + ' Loop'
			for xml raw ('LOOP-INFO'), type
		)
--- </Body>

---	<Return>
	return
		@xmlOutput
end
go

select
	EDI_XML.LOOP_INFO ('HL')