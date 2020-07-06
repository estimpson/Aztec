use FxAztec
go

select
	wsn.Status
,	wsn.Type
,	wsn.RawDocumentGUID
,	wsn.ShipperID
,	wsn.BillOfLadingNumber
,	wsn.ShipFromCode
,	wsn.ShipToCode
,	wsn.ShipDT
,	AlertsSummary = FX.ToList(Alerts.AlertType + '[' + convert(varchar(12), Alerts.AlertCount) + ']')
from
	SUPPLIEREDI.WaupacaShipNotices wsn
	outer apply
	(	select
			wsna.RawDocumentGUID
		,	AlertType = case when wsna.Type < 0 then 'Error' else 'Warning' end
		,	AlertCount = count(*)
		from
			SUPPLIEREDI.WaupacaShipNoticeAlerts wsna
		where
			wsna.RawDocumentGUID = wsn.RawDocumentGUID
		group by
			wsna.RawDocumentGUID
		,	case when wsna.Type < 0 then 'Error' else 'Warning' end
	) Alerts
where
	wsn.Status = 0
group by
	wsn.Status
,	wsn.Type
,	wsn.RawDocumentGUID
,	wsn.ShipperID
,	wsn.BillOfLadingNumber
,	wsn.ShipFromCode
,	wsn.ShipToCode
,	wsn.ShipDT

select
	*
from
	SUPPLIEREDI.WaupacaShipNoticeAlerts wsna
order by
	wsna.ShipDT
,	wsna.ShipperID
,	wsna.RawDocumentGUID
,	wsna.Type
,	wsna.Alert
