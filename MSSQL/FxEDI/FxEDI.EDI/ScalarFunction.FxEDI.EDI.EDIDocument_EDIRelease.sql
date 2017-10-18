
/*
Create ScalarFunction.FxEDI.EDI.EDIDocument_EDIRelease.sql
*/

use FxEDI
go

if	objectproperty(object_id('EDI.EDIDocument_EDIRelease'), 'IsScalarFunction') = 1 begin
	drop function EDI.EDIDocument_EDIRelease
end
go

create function EDI.EDIDocument_EDIRelease
(	@XMLData xml
)
returns varchar(10)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/TRN-INFO[1]/@release', 'varchar(25)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end
go

