
/*
Create ScalarFunction.FxEDI.EDI.EDIDocument_DocNumber.sql
*/

use FxEDI
go

if	objectproperty(object_id('EDI.EDIDocument_DocNumber'), 'IsScalarFunction') = 1 begin
	drop function EDI.EDIDocument_DocNumber
end
go

create function EDI.EDIDocument_DocNumber
(	@XMLData xml
)
returns varchar(10)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/TRN-INFO[1]/@doc_number', 'varchar(50)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end
go

