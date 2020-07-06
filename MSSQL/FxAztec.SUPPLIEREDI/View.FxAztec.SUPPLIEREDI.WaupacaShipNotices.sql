
/*
Create View.FxAztec.SUPPLIEREDI.WaupacaShipNotices.sql
*/

use FxAztec
go

--drop table SUPPLIEREDI.WaupacaShipNotices
if	objectproperty(object_id('SUPPLIEREDI.WaupacaShipNotices'), 'IsView') = 1 begin
	drop view SUPPLIEREDI.WaupacaShipNotices
end
go

create view SUPPLIEREDI.WaupacaShipNotices
as
select
	snh.Status
,	snh.Type
,	snh.RawDocumentGUID
,	sno.ShipperID
,	BillOfLadingNumber = sn.Trailer
,	ShipFromCode = sn.ShipFromCode
,	ShipToCode = ph.ship_to_destination
,	ShipDT = snh.DocumentDT
from
	FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
	join FxEDI.EDI4010_WAUPACA.ShipNotices sn
		on sn.RawDocumentGUID = snh.RawDocumentGUID
	join FxEDI.EDI4010_WAUPACA.ShipNoticeOrders sno
		on sno.RawDocumentGUID = snh.RawDocumentGUID
	join dbo.po_header ph
		on ph.po_number = sno.PurchaseOrder
group by
	snh.Status
,	snh.Type
,	snh.RawDocumentGUID
,	sno.ShipperID
,	sn.Trailer
,	sn.ShipFromCode
,	ph.ship_to_destination
,	snh.DocumentDT
go

select
	*
from
	SUPPLIEREDI.WaupacaShipNotices as wsn
where
	wsn.Status = 0
