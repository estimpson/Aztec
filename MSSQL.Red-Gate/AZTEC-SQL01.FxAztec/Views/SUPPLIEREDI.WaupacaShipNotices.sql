SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [SUPPLIEREDI].[WaupacaShipNotices]
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
GO
