
/*
Create View.FxAztec.SUPPLIEREDI.WaupacaShipNoticeLines.sql
*/

use FxAztec
go

--drop table SUPPLIEREDI.WaupacaShipNoticeLines
if	objectproperty(object_id('SUPPLIEREDI.WaupacaShipNoticeLines'), 'IsView') = 1 begin
	drop view SUPPLIEREDI.WaupacaShipNoticeLines
end
go

create view SUPPLIEREDI.WaupacaShipNoticeLines
as

select
	snh.Status
,	snh.Type
,	snh.RawDocumentGUID
,	SupplierPart = snl.PartNumber
,	PurchaseOrderRef = sno.PurchaseOrder
,	snl.Quantity
,	PartCode = phBestMatch.blanket_part
,	PurchaseOrderNumber = phBestMatch.po_number
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
group by
	snh.Status
,	snh.Type
,	snh.RawDocumentGUID
,	snl.PartNumber
,	sno.PurchaseOrder
,	snl.Quantity
,	phBestMatch.po_number
,	phBestMatch.blanket_part
go

select
	*
from
	SUPPLIEREDI.WaupacaShipNoticeLines as wsnl
where
	wsnl.Status = 0