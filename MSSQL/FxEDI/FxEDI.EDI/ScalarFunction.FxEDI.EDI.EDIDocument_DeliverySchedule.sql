
/*
Create ScalarFunction.FxEDI.EDI.EDIDocument_DeliverySchedule.sql
*/

use FxEDI
go

if	objectproperty(object_id('EDI.EDIDocument_DeliverySchedule'), 'IsScalarFunction') = 1 begin
	drop function EDI.EDIDocument_DeliverySchedule
end
go

create function EDI.EDIDocument_DeliverySchedule
(	@XMLData xml
)
returns varchar(10)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/SEG-BGM[1]/CE[@code="C002"][1]/DE[@code="1001"][1]', 'varchar(8)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end
go

