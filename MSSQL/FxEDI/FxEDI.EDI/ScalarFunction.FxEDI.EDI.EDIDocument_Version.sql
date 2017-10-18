
/*
Create ScalarFunction.FxEDI.EDI.EDIDocument_Version.sql
*/

use FxEDI
go

if	objectproperty(object_id('EDI.EDIDocument_Version'), 'IsScalarFunction') = 1 begin
	drop function EDI.EDIDocument_Version
end
go

create function EDI.EDIDocument_Version
(	@XMLData xml
)
returns varchar(10)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/TRN-INFO[1]/@version', 'varchar(20)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end
go

