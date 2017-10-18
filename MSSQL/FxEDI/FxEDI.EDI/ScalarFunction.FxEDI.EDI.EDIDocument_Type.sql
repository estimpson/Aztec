
/*
Create ScalarFunction.FxEDI.EDI.EDIDocument_Type.sql
*/

use FxEDI
go

if	objectproperty(object_id('EDI.EDIDocument_Type'), 'IsScalarFunction') = 1 begin
	drop function EDI.EDIDocument_Type
end
go

create function EDI.EDIDocument_Type
(	@XMLData xml
)
returns varchar(10)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('*[1]/TRN-INFO[1]/@type', 'varchar(6)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end
go

