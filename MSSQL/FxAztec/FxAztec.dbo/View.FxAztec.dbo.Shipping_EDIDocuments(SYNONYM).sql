
/*
Create View.FxAztec.dbo.Shipping_EDIDocuments(SYNONYM).sql
*/

use FxAztec
go

if	objectpropertyex(object_id('dbo.Shipping_EDIDocuments'), 'BaseType') = 'V' begin
	drop synonym dbo.Shipping_EDIDocuments
end
go

create synonym dbo.Shipping_EDIDocuments for SHIP.EDIDocuments
go

select
	objectpropertyex(object_id('dbo.Shipping_EDIDocuments'), 'BaseType')
