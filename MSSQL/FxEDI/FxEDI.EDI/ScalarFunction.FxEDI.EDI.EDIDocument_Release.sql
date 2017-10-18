
/*
Create ScalarFunction.FxEDI.EDI.EDIDocument_Release.sql
*/

use FxEDI
go

if	objectproperty(object_id('EDI.EDIDocument_Release'), 'IsScalarFunction') = 1 begin
	drop function EDI.EDIDocument_Release
end
go

create function EDI.EDIDocument_Release
(	@XMLData xml
)
returns varchar(10)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/TRN-INFO[1]/@doc_number', 'varchar(25)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end
go

