
/*
Create ScalarFunction.FxEDI.EDI.EDIDocument_TradingPartner.sql
*/

use FxEDI
go

if	objectproperty(object_id('EDI.EDIDocument_TradingPartner'), 'IsScalarFunction') = 1 begin
	drop function EDI.EDIDocument_TradingPartner
end
go

create function EDI.EDIDocument_TradingPartner
(	@XMLData xml
)
returns varchar(10)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/TRN-INFO[1]/@trading_partner', 'varchar(50)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end
go

