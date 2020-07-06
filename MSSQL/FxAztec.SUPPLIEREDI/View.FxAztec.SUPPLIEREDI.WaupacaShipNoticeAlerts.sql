
/*
Create View.FxAztec.SUPPLIEREDI.WaupacaShipNoticeAlerts.sql
*/

use FxAztec
go

--drop table SUPPLIEREDI.WaupacaShipNoticeAlerts
if	objectproperty(object_id('SUPPLIEREDI.WaupacaShipNoticeAlerts'), 'IsView') = 1 begin
	drop view SUPPLIEREDI.WaupacaShipNoticeAlerts
end
go

create view SUPPLIEREDI.WaupacaShipNoticeAlerts
as
/*	No valid matching PO. */
select
	wsn.Status
,	Type = -1
,	Alert = 'No valid matching PO.'
,	wsn.RawDocumentGUID
,	wsn.ShipperID
,	wsn.BillOfLadingNumber
,	wsn.ShipFromCode
,	wsn.ShipToCode
,	wsn.ShipDT
,	poMissing.Description
,	poMissing.Data
from
	SUPPLIEREDI.WaupacaShipNotices wsn
	outer apply
	(	select
 			Description = FX.ToList('PORef: ' + convert(varchar(12), wsnl.PurchaseOrderRef) + ' SPN: ' + wsnl.SupplierPart)
		,	Data = FX.ToList('(' + convert(varchar(12), wsnl.PurchaseOrderRef) + ',' + wsnl.SupplierPart + ')')
		 	from
		 		SUPPLIEREDI.WaupacaShipNoticeLines wsnl
			where
				wsnl.RawDocumentGUID = wsn.RawDocumentGUID
				and wsnl.PurchaseOrderNumber is null
	) poMissing
where
	wsn.Status = 0
	and exists
		(	select
				*
			from
				SUPPLIEREDI.WaupacaShipNoticeLines wsnl
			where
				wsnl.RawDocumentGUID = wsn.RawDocumentGUID
				and wsnl.PurchaseOrderNumber is null
		)
union all
/*	Possible duplicate. */
select
	wsn.Status
,	Type = 1
,	Alert = 'Possible duplicate receipts.'
,	wsn.RawDocumentGUID
,	wsn.ShipperID
,	wsn.BillOfLadingNumber
,	wsn.ShipFromCode
,	wsn.ShipToCode
,	wsn.ShipDT
,	Reciepts.Description
,	Reciepts.Data
from
	SUPPLIEREDI.WaupacaShipNotices wsn
	outer apply
	(	select
 			Description = FX.ToList('RN: ' + R.ReceiverNumber + ':' + convert(varchar(12), R.Status) + coalesce(' PO#: ' + convert(varchar(12), R.PONumber) + ' PN: ' + R.PartCode + ' QTY: ' + convert(varchar(12), R.Quantity), ''))
		,	Data = Fx.ToList(R.ReceiverNumber)
 		from
			(	select
					rh.ReceiverNumber
				,	rh.Status
				,	rl.PONumber
				,	rl.PartCode
				,	Quantity = sum(ro.QtyObject)
				from
 					dbo.ReceiverHeaders rh
					left join dbo.ReceiverLines rl
						on rl.ReceiverID = rh.ReceiverID
					left join dbo.ReceiverObjects ro
						on ro.ReceiverLineID = rl.ReceiverLineID
						and ro.Serial > 0
				where
					rh.ShipFrom = wsn.ShipFromCode
					and rh.Plant = wsn.ShipToCode
					and rh.ConfirmedSID = wsn.ShipperID
				group by
					rh.ReceiverNumber
				,	rh.Status
				,	rl.PONumber
				,	rl.PartCode
			) R
 	) Reciepts
where
	wsn.Status = 0
	and exists
		(	select
				*
			from
				dbo.ReceiverHeaders rh
			where
				rh.ShipFrom = wsn.ShipFromCode
				and rh.Plant = wsn.ShipToCode
				and rh.ConfirmedSID = wsn.ShipperID
		)
union all
/*	No part-vendor record with matching vendor part. */
select
	wsn.Status
,	Type = 2
,	Alert = 'No part-vendor record with matching vendor part.'
,	wsn.RawDocumentGUID
,	wsn.ShipperID
,	wsn.BillOfLadingNumber
,	wsn.ShipFromCode
,	wsn.ShipToCode
,	wsn.ShipDT
,	pvMissing.Description
,	pvMissing.Data
from
	SUPPLIEREDI.WaupacaShipNotices wsn
	outer apply
	(	select
 			Description = FX.ToList('SPN: ' + wsnl.SupplierPart + ' PN:' + wsnl.PartCode)
		,	Data = Fx.ToList('(' + wsnl.PartCode  + ',' + dv.vendor + ',' + wsnl.SupplierPart + ')')
		from
			SUPPLIEREDI.WaupacaShipNoticeLines wsnl
			join dbo.destination dV
				on dV.destination = wsn.ShipFromCode
			left join dbo.part_vendor pv
				on dV.vendor = pv.vendor
				and pv.vendor_part = wsnl.SupplierPart
		where
			wsnl.RawDocumentGUID = wsn.RawDocumentGUID
			and pv.part is null
	) pvMissing
where
	wsn.Status = 0
	and exists
		(	select
		 		*
		 	from
		 		SUPPLIEREDI.WaupacaShipNoticeLines wsnl
				left join dbo.part_vendor pv
					join dbo.destination dV
						on dV.vendor = pv.vendor
					on dV.destination = wsn.ShipFromCode
					and pv.vendor_part = wsnl.SupplierPart
			where
				wsnl.RawDocumentGUID = wsn.RawDocumentGUID
				and pv.part is null
		)
union all
/*	PO Number was inferred from ship from, ship to, and part. */
select
	wsn.Status
,	Type = 3
,	Alert = 'PO Number was inferred from ship from, ship to, and part.'
,	wsn.RawDocumentGUID
,	wsn.ShipperID
,	wsn.BillOfLadingNumber
,	wsn.ShipFromCode
,	wsn.ShipToCode
,	wsn.ShipDT
,	poMismatch.Description
,	poMismatch.Data
from
	SUPPLIEREDI.WaupacaShipNotices wsn
	outer apply
	(	select
 			Description = FX.ToList('PORef: ' + convert(varchar(12), wsnl.PurchaseOrderRef) + ' PO:' + convert(varchar(12), wsnl.PurchaseOrderNumber))
		,	Data = FX.ToList('(' + convert(varchar(12), wsnl.PurchaseOrderRef) + ',' + convert(varchar(12), wsnl.PurchaseOrderNumber) + ')')
		 	from
		 		SUPPLIEREDI.WaupacaShipNoticeLines wsnl
			where
				wsnl.RawDocumentGUID = wsn.RawDocumentGUID
				and wsnl.PurchaseOrderRef <> wsnl.PurchaseOrderNumber
	) poMismatch
where
	wsn.Status = 0
	and exists
		(	select
		 		*
		 	from
		 		SUPPLIEREDI.WaupacaShipNoticeLines wsnl
			where
				wsnl.RawDocumentGUID = wsn.RawDocumentGUID
				and wsnl.PurchaseOrderRef <> wsnl.PurchaseOrderNumber
		)
go

select
	*
from
	SUPPLIEREDI.WaupacaShipNoticeAlerts wsna
order by
	wsna.RawDocumentGUID
,	wsna.Type
,	wsna.Alert
