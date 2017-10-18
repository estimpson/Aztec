
/*
Create ScalarFunction.FxEDI.EDI.EDIDocument_ControlNumber.sql
*/

use FxEDI
go

if	objectproperty(object_id('EDI.EDIDocument_ControlNumber'), 'IsScalarFunction') = 1 begin
	drop function EDI.EDIDocument_ControlNumber
end
go

create function EDI.EDIDocument_ControlNumber
(	@XMLData xml
)
returns varchar(10)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/TRN-INFO[1]/@control_number', 'varchar(10)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end
go

