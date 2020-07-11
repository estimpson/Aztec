SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [SUPPLIEREDI].[WaupacaShipNoticeLines]
as

select
	snl.Status
,	snh.Type
,	snh.RawDocumentGUID
,	SupplierPart = snl.PartNumber
,	PurchaseOrderRef = sno.PurchaseOrder
,	snl.Quantity
,	PartCode = phBestMatch.blanket_part
,	PurchaseOrderNumber = phBestMatch.po_number
,	snl.RowID
from
	FxEDI.EDI4010_WAUPACA.ShipNoticeHeaders snh
	join FxEDI.EDI4010_WAUPACA.ShipNotices sn
		on sn.RawDocumentGUID = snh.RawDocumentGUID
	join FxEDI.EDI4010_WAUPACA.ShipNoticeOrders sno
		on sno.RawDocumentGUID = snh.RawDocumentGUID
	join FxEDI.EDI4010_WAUPACA.ShipNoticeLines snl
		on snl.RawDocumentGUID = snh.RawDocumentGUID
		and snl.PurchaseOrder = sno.PurchaseOrder
	left join dbo.po_header ph
		on ph.po_number = sno.PurchaseOrder
	outer apply
	(	select top (1)
	 		*
	 	from
	 		dbo.po_header phBestMatch
			outer apply
			(	select
	 				FuzzyPartNumber = substring(snl.PartNumber, r.RowNumber, 4)
	 			from
	 				FxEDI.FXSYS.Rows r
				where
					r.RowNumber <= datalength(snl.PartNumber) - 3
					and substring(snl.PartNumber, r.RowNumber, 4) like '[0-9][0-9][0-9][0-9]'
			) r
		where
			phBestMatch.vendor_code = ph.vendor_code
			and phBestMatch.ship_to_destination = ph.ship_to_destination
			and phBestMatch.blanket_part like '%' + r.FuzzyPartNumber + '%'
		order by
			phBestMatch.po_number
	) phBestMatch
GO
