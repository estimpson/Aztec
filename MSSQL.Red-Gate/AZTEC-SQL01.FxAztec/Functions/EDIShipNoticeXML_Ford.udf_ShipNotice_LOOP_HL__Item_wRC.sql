SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_ShipNotice_LOOP_HL__Item_wRC]
(	@ShipperID INT
)
RETURNS XML
AS
BEGIN
--- <Body>

-- Select  [EDIShipNoticeXML_Ford].[udf_ShipNotice_LOOP_HL__Item_wRC] (1069704)

DECLARE @ShippedSerials TABLE
(
  ID INT IDENTITY (1,1),
  ShipperID INT,
  Customerpart VARCHAR(30),
  Packagetype VARCHAR(30),
  Returnable INT,
  PackQty INT,
  SerialNo INT
)

DECLARE @ShippedCustomerParts TABLE
(
  ID INT IDENTITY (2,1),
  ShipperID INT,
  Customerpart VARCHAR(30),
   QtyShipped INT,
  PartType varchar(2)
 
)
INSERT INTO @ShippedSerials 

SELECT	s.id,
		sd.customer_part,
		COALESCE(NULLIF(at.package_type,''), 'CTN90'),
		CASE WHEN Coalesce(pm.returnable,'N') = 'Y' THEN 1 ELSE 0 END,
		at.quantity,
		at.serial

FROM
	dbo.Shipper s
JOIN
	dbo.shipper_detail sd ON sd.shipper = s.id
JOIN
	audit_trail at ON at.shipper = CONVERT(VARCHAR(30), s.id ) AND at.part = sd.part_original and at.type = 'S'
AND
	s.id = @ShipperID
LEFT JOIN
	package_materials pm on pm.code = at.package_type

INSERT @ShippedCustomerparts
        ( ShipperID, Customerpart, QtyShipped, PartType )
SELECT
	ShipperID,
	Customerpart,
	sum(PackQty),
	'BP'
FROM
	@ShippedSerials
GROUP BY
	ShipperID,
	CustomerPart
UNION
SELECT
	ShipperID,
	PackageType,
	sum(Returnable),
	'RC'
FROM
	@ShippedSerials
Where
	Returnable = 1
GROUP BY
 ShipperID,
 PackageType

ORDER BY
	4,2
	
	DECLARE	@outputXML XML

	SET	@outputXML =
		(SELECT  (SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_INFO_HL]()) ,
		(SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_HL__HierarchicalLevel] (scp.id)),
		( CASE WHEN PartType = 'BP' THEN (SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_LIN__Buyerpart]( scp.ShipperID, scp.Customerpart )) WHEN PartType = 'RC'  THEN (SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_LIN__ReturnableContainer]( scp.Customerpart )) END),
		( CASE WHEN PartType = 'BP' THEN ( SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_LIN__QtyShipped]( scp.ShipperID, scp.Customerpart ))  WHEN PartType = 'RC' THEN (SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_LIN__QtyShipped_RC]( max(scp.QtyShipped) )) END),
		COALESCE(( CASE WHEN PartType = 'BP' THEN (SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_PRF__CustomerPO]( scp.ShipperID, scp.Customerpart )) END),''),		
		COALESCE(( CASE WHEN PartType = 'BP' THEN (SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLItem_SEG_MEA__GrossWeight]( scp.ShipperID, scp.Customerpart )) END),''),
		COALESCE(( CASE WHEN PartType = 'BP' THEN (SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLItem_SEG_MEA__NetWeight]( scp.ShipperID, scp.Customerpart )) END),''),
		COALESCE((SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_LOOP_CLD__CLD] (ss.ShipperID, ss.Customerpart, ss.packQty, COUNT(1)) 
			FROM @ShippedSerials ss 
			WHERE ss.Customerpart = scp.Customerpart AND ss.ShipperID = scp.ShipperID  AND scp.PartType != 'RC'
			GROUP BY ss.ShipperID, ss.Customerpart, ss.PackQty 
			FOR XML PATH('LOOP-CLD'), TYPE ),'')
						
			
FROM
	@ShippedCustomerParts  scp
LEFT JOIN
	@ShippedSerials ss1 ON ss1.Customerpart = scp.Customerpart AND ss1.ShipperID = scp.ShipperID
GROUP BY
	scp.ID,
	scp.Customerpart,
	scp.ShipperID,
	scp.PartType
ORDER BY
	scp.ID ASC
FOR XML PATH('LOOP-HL')

)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END














GO
