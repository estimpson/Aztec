SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE FUNCTION [EDI_XML_Ford_ASN].[ASNLines]
(	@shipperID INT
)
RETURNS @ASNLines TABLE
(	ShipperID INT
,	CustomerPart VARCHAR(30)
,	QtyPacked INT
,	UnitPacked CHAR(2)
,	AccumQty INT
,	CustomerPO VARCHAR(25)
,	GrossWeight INT
,	NetWeight INT
,	BoxType VARCHAR(20)
,	BoxQty INT
,	BoxCount INT
,	RowNumber INT
)
AS
BEGIN
--- <Body>
	--declare
	--	@at table
	--(	Part varchar(25)
	--,	BoxType varchar(20)
	--,	BoxQty int
	--,	BoxCount int
	--)

	--insert
	--	@at
	--(	Part
	--,	BoxType
	--,	BoxQty
	--,	BoxCount
	--)
	--select
	--	Part = at.part
	--,	BoxType = coalesce(case when pm.type = 'R' then at.package_type end, 'CTN90')
	--,	BoxQty = convert(int, round(at.std_quantity,0))
	--,	BoxCount = count(*)
	--from
	--	dbo.audit_trail at
	--	join dbo.package_materials pm
	--		on pm.code = at.package_type
	--where
	--	at.shipper = convert(varchar, @shipperID)
	--	and at.type = 'S'
	--group by
	--	at.part
	--,	coalesce(case when pm.type = 'R' then at.package_type end, 'CTN90')
	--,	at.std_quantity

	INSERT
		@ASNLines
	(	ShipperID
	,	CustomerPart
	,	QtyPacked
	,	UnitPacked
	,	AccumQty
	,	CustomerPO
	,	GrossWeight
	,	NetWeight
	,	BoxType
	,	BoxQty
	,	BoxCount
	,	RowNumber
	)
	SELECT
		ShipperID = s.id
	,	CustomerPart = sd.customer_part
	,	QtyPacked = CONVERT(INT, ROUND(sd.alternative_qty, 0))
	,	UnitPacked = sd.alternative_unit
	--,	AccumQty =
	--		CASE
	--			WHEN es.prev_cum_in_asn = 'Y'
	--				THEN CONVERT(INT, ROUND(sd.accum_shipped - sd.alternative_qty, 0))
	--			ELSE CONVERT(INT, ROUND(sd.accum_shipped, 0))
	--		END
	,	AccumQty = sd.accum_shipped - coalesce(PriorShipmentQty,0)
	,	CustomerPO = sd.customer_po
	,	GrossWeight = CONVERT(INT, ROUND(sd.gross_weight, 0))
	,	NetWeight = CONVERT(INT, ROUND(sd.net_weight, 0))
	,	BoxType = 'CTN90'
	--,	BoxQty = at.BoxQty
	,	BoxQty = 1
	--,	BoxCount = at.BoxCount
	,	BoxCount = 1
	,	RowNumber = ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY sd.customer_part/*, at.BoxCount*/)
	--,	*
	FROM
		dbo.shipper s
		JOIN dbo.edi_setups es
			ON s.destination = es.destination
			AND es.asn_overlay_group LIKE 'FD%'
		JOIN dbo.destination d
			ON d.destination = s.destination
		JOIN dbo.shipper_detail sd
			JOIN dbo.order_header oh
				ON oh.order_no = sd.order_no
				AND oh.blanket_part = sd.part
			ON sd.shipper = s.id
		Cross Apply 
					( Select sum(sd2.qty_packed) as PriorShipmentQty
						from shipper_detail sd2 
						join shipper s on s.id =  sd2.shipper
						Join edi_setups es on es.destination = s.destination and isNULL(es.prev_cum_in_asn,'N') = 'Y'
						where sd2.order_no =  sd.Order_no and 
								sd2.date_shipped < sd.date_shipped and
								sd2.date_shipped >= [FT].[fn_TruncDate]('d', getdate()) and
								s.date_shipped is not NULL and
								s.status in ('C', 'Z') )  PriorShipmentsToday
		--JOIN @at at
		--	ON at.Part = sd.part
	WHERE
		COALESCE(s.type, 'N') IN ('N', 'M')
		AND s.id = @shipperID
--- </Body>

---	<Return>
	RETURN
END



GO
