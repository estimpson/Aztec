begin transaction
go

select
	*
from
	SPORTAL.SupplierShipmentsASN ssa
	join SPORTAL.SupplierShipmentsASNLines ssal
		on ssal.SupplierShipmentsASNRowID = ssa.RowID
go

exec
	SPORTAL.usp_SupplierShipments_ProcessASN
	@SupplierCode = 'HIB0010'
,	@ShipperID = '_test'


select
	*
from
	SPORTAL.SupplierShipmentsASN ssa
	join SPORTAL.SupplierShipmentsASNLines ssal
		on ssal.SupplierShipmentsASNRowID = ssa.RowID

select
	sn.RawDocumentGUID
,	sn.RowID
,	sn.ShipperID
,	sn.BillOfLadingNumber
,	sn.ShipFromCode
,	sn.ShipToCode
,	sn.ShipDT
,	snl.RowID
,	snl.SupplierPart
,	snl.PurchaseOrderRef
,	snl.Quantity
,	snl.PartCode
,	snl.PurchaseOrderNumber
,	sno.RowID
,	sno.SupplierSerial
,	sno.SupplierParentSerial
,	sno.SupplierPackageType
,	sno.SupplierLot
,	sno.ObjectQuantity
,	sno.ObjectSerial
,	sno.ObjectParentSerial
,	sno.ObjectPackageType
,	OutsideProcess = case when OP.OP = 1 then 1 else 0 end
from
	SUPPLIEREDI.ShipNotices sn with (tablockx)
	join SUPPLIEREDI.ShipNoticeLines snl with (tablockx)
		on snl.RawDocumentGUID = sn.RawDocumentGUID
	join SUPPLIEREDI.ShipNoticeObjects sno with (tablockx)
		on sno.RawDocumentGUID = sn.RawDocumentGUID
		and sno.SupplierPart = snl.SupplierPart
	outer apply
	(	select top(1)
			OP = 1
		from
			dbo.part_machine pmOP
		where
			pmOP.part = snl.PartCode
			and pmOP.machine = sn.ShipFromCode
		order by
			pmOP.sequence
	) OP
where
	sn.Status = 0
	and snl.Quantity is not null
	--and snl.PurchaseOrderNumber is not null
	--and snl.PartCode is not null
	--and sno.ObjectQuantity is not null

select
	*
from
	SUPPLIEREDI.ShipNotices sn
	join SUPPLIEREDI.ShipNoticeLines snl
		join SUPPLIEREDI.ShipNoticeObjects sno
		on sno.RawDocumentGUID = snl.RawDocumentGUID AND sno.SupplierPart = snl.SupplierPart
	on snl.RawDocumentGUID = sn.RawDocumentGUID

select
	*
from
	dbo.ReceiverHeaders rh
	left join dbo.ReceiverLines rl
		left join dbo.ReceiverObjects ro
			on ro.ReceiverLineID = rl.ReceiverLineID
		on rl.ReceiverID = rh.ReceiverID
where
	rh.ShipFrom = 'HIB0010'
	--and rh.ConfirmedSID like '%test%'
go

rollback
go
