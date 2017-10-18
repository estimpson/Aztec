
/*
Create View.FxAztec.dbo.Shipping_DepartedShipperList(SYNONYM).sql
*/

use FxAztec
go

if	objectpropertyex(object_id('dbo.Shipping_DepartedShipperList'), 'BaseType') = 'V' begin
	drop synonym dbo.Shipping_DepartedShipperList
end
go

create synonym dbo.Shipping_DepartedShipperList for SHIP.DepartedShipperList
go

select
	objectpropertyex(object_id('dbo.ShippinShipping_DepartedShipperListg_EDIDocuments'), 'BaseType')
go

