SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [EDI_XML_Ford_ASN].[ASNHeaders]
AS
SELECT
	ShipperID = s.id
,	iConnectID = es.IConnectID
,	TradingPartnerID = es.trading_partner_code
,	ShipDateTime = s.date_shipped
,	ShipDate = CONVERT(DATE, s.date_shipped)
,	ShipTime = CONVERT(TIME, s.date_shipped)
,	GrossWeight = CONVERT(INT, ROUND(s.gross_weight, 0))
,	NetWeight = CONVERT(INT, ROUND(s.net_weight, 0))
,	PackageType =
		CASE
			WHEN s.staged_pallets > 0 THEN 'PLT90'
			ELSE 'CTN90'
		END
,	BOLQuantity =
		CASE
			WHEN s.staged_pallets > 0 THEN s.staged_pallets
			ELSE s.staged_objs
		END
,	Carrier = s.ship_via
,	BOLCarrier = COALESCE(s.bol_carrier, s.ship_via)
,	TransMode = s.trans_mode
,	LocationQualifier =
		CASE
			WHEN s.trans_mode = 'E' THEN NULL
			WHEN s.trans_mode IN ('A', 'AE') THEN 'OR'
			WHEN es.pool_code != '' THEN 'PP'
		END
,	PoolCode =
		CASE
			WHEN s.trans_mode = 'E' THEN NULL
			WHEN s.trans_mode IN ('A', 'AE') THEN 'DTW'
			ELSE es.pool_code
		END
,	EquipmentType = es.equipment_description
,	TruckNumber = s.truck_number
,	PRONumber = s.pro_number
,	BOLNumber =
		CASE
			WHEN es.parent_destination = 'milkrun' THEN SUBSTRING(es.material_issuer, DATEPART(dw, s.date_shipped)*2-1, 2) + RIGHT('0'+CONVERT(VARCHAR, DATEPART(MONTH, s.date_shipped)),2) + RIGHT('0'+CONVERT(VARCHAR, DATEPART(DAY, s.date_shipped)),2)
			ELSE CONVERT(VARCHAR, s.bill_of_lading_number)
		END
,	ShipTo = LEFT(s.destination, 5)
,	SupplierCode = es.supplier_code
,	ICCode = [EDI_XML_Ford_ASN].[udfGetIntermediateConsignee](s.id)
--,	*
FROM
	dbo.shipper s
	JOIN dbo.edi_setups es
		ON s.destination = es.destination
		AND es.asn_overlay_group LIKE 'FD%'
	JOIN dbo.destination d
		ON d.destination = s.destination 
WHERE
	COALESCE(s.type, 'N') IN ('N', 'M')
	AND s.date_shipped >= DATEADD(dd, -1, GETDATE())
	--and s.id = 83453


GO
