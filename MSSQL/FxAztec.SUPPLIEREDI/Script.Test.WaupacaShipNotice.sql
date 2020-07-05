use FxAztec
go

--	dbo.usp_Purchasing_Receive
select
	sn.Status
,	sn.Type
,	sn.RawDocumentGUID
,	sn.ShipperID
,	sn.BillOfLadingNumber
,	sn.ShipFromCode
,	sn.ShipToCode
,	sn.ShipDT
from
	SUPPLIEREDI.ShipNotices sn

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

select
	snl.Status
,	snl.Type
,	snl.RawDocumentGUID
,	snl.SupplierPart
,	snl.PurchaseOrderRef
,	snl.Quantity
,	snl.PartCode
,	snl.PurchaseOrderNumber
,	snl.RowID
,	snl.RowCreateDT
,	snl.RowCreateUser
,	snl.RowModifiedDT
,	snl.RowModifiedUser
from
	SUPPLIEREDI.ShipNoticeLines snl