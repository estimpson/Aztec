
/*
Create ScalarFunction.FxEDI.EDI.EDIDocument_MessageNumber.sql
*/

use FxEDI
go

if	objectproperty(object_id('EDI.EDIDocument_MessageNumber'), 'IsScalarFunction') = 1 begin
	drop function EDI.EDIDocument_MessageNumber
end
go

create function EDI.EDIDocument_MessageNumber
(	@XMLData xml
)
returns varchar(10)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/SEG-BGM[1]/CE[@code="C106"][1]/DE[@code="1004"][1]', 'varchar(8)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end
go

