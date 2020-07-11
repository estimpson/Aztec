
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
,	ShipperLineStatus = snl.Status
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
	join FxEDI.EDI4010_WAUPACA.ShipNoticeLines snl
		on snl.RawDocumentGUID = snh.RawDocumentGUID
		and snl.PurchaseOrder = sno.PurchaseOrder
	join dbo.po_header ph
		on ph.po_number = sno.PurchaseOrder
group by
	snh.Status
,	snl.Status
,	snh.Type
,	snh.RawDocumentGUID
,	sno.ShipperID
,	sn.Trailer
,	sn.ShipFromCode
,	ph.ship_to_destination
,	snh.DocumentDT
go

select
	wsn.Status
,	wsn.ShipperLineStatus
,	wsn.Type
,	wsn.RawDocumentGUID
,	wsn.ShipperID
,	wsn.BillOfLadingNumber
,	wsn.ShipFromCode
,	wsn.ShipToCode
,	wsn.ShipDT
from
	SUPPLIEREDI.WaupacaShipNotices as wsn
where
	wsn.Status = 0
