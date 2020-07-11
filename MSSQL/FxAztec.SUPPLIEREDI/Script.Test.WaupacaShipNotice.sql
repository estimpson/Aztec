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


select
	wsn.ShipperID
,	wsn.BillOfLadingNumber
,	wsn.ShipFromCode
,	wsn.ShipToCode
,	wsn.ShipDT
,	RawDocumentGUIDList = FX.ToList(wsn.RawDocumentGUID)
,	Alerts.InformationCount
,	Alerts.WarningCount
,	Alerts.ErrorCount
,	Changed = convert(varchar(1000), '')
,	IsSelected = 0
from
	SUPPLIEREDI.WaupacaShipNotices as wsn
	outer apply
	(	select
			InformationCount = count(case when wsna.Type = 0 then 1 end)
		,	WarningCount = count(case when wsna.Type > 0 then 1 end)
		,	ErrorCount = count(case when wsna.Type < 0 then 1 end)
		from
			SUPPLIEREDI.WaupacaShipNoticeAlerts wsna
		where
			wsna.ShipperID = wsn.ShipperID
			and wsna.BillOfLadingNumber = wsn.BillOfLadingNumber
			and wsna.ShipFromCode = wsn.ShipFromCode
			and wsna.ShipToCode = wsn.ShipToCode
			and wsna.ShipDT = wsn.ShipDT
	) Alerts
where
	wsn.Status = 0
group by
	wsn.ShipperID
,	wsn.BillOfLadingNumber
,	wsn.ShipFromCode
,	wsn.ShipToCode
,	wsn.ShipDT
,	Alerts.InformationCount
,	Alerts.WarningCount
,	Alerts.ErrorCount
order by
	wsn.ShipDT
,	wsn.ShipperID

select
	*
from
	SUPPLIEREDI.WaupacaShipNoticeLines wsnl
where
	wsnl.RawDocumentGUID in ('D35F5CD8-D5B4-EA11-8121-005056A166E5', 'D15F5CD8-D5B4-EA11-8121-005056A166E5')