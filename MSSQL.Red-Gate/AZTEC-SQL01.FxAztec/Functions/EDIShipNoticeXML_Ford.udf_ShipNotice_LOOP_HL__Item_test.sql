SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_ShipNotice_LOOP_HL__Item_test]
(	@ShipperID INT
)
RETURNS XML
AS
BEGIN
--- <Body>

-- Select  [EDIShipNoticeXML_Ford].[udf_ShipNotice_LOOP_HL__Item] (1071280)

DECLARE @ShippedSerials TABLE
(
  ID INT IDENTITY (1,1),
  ShipperID INT,
  Customerpart VARCHAR(30),
  Packagetype VARCHAR(30),
  PackQty INT,
  SerialNo INT
)

DECLARE @ShippedCustomerParts TABLE
(
  ID INT IDENTITY (2,1),
  ShipperID INT,
  Customerpart VARCHAR(30)
)
INSERT INTO @ShippedSerials 

SELECT	s.id,
		sd.customer_part,
		COALESCE(NULLIF(at.package_type,''), 'CTN90'),
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

INSERT @ShippedCustomerparts
        ( ShipperID, Customerpart )
SELECT
	DISTINCT 
	ShipperID,
	Customerpart
FROM
	@ShippedSerials
ORDER BY
	Customerpart

	DECLARE @ShippedReturnables TABLE
(
  ID INT IDENTITY (200,1),
  ShipperID INT,
  ReturnablePart VARCHAR(30) ,
  QtyShipped INT
)

INSERT @ShippedReturnables
        ( ShipperID, ReturnablePart, QtyShipped )
SELECT
	at.shipper,
	at.package_type,
	count(1)
FROM
	audit_trail at
join
	package_materials pm on pm.code =  at.package_type
Where 
	at.type = 'S' and
	at.shipper = convert(varchar(20), @ShipperID) and
	pm.returnable = 'Y'
group by
	at.shipper,
	at.package_type
order by
at.package_type



	DECLARE	@outputXML XML

	SET	@outputXML =
		(SELECT  (SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_INFO_HL]()) ,
		(SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_HL__HierarchicalLevel] (scp.id)),
		(SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_LIN__Buyerpart]( scp.ShipperID, scp.Customerpart )),
		(SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_LIN__QtyShipped]( scp.ShipperID, scp.Customerpart )), 
		(SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_PRF__CustomerPO]( scp.ShipperID, scp.Customerpart )),		
		(SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLItem_SEG_MEA__GrossWeight]( scp.ShipperID, scp.Customerpart )),
		(SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLItem_SEG_MEA__NetWeight]( scp.ShipperID, scp.Customerpart )),
		(SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_LOOP_CLD__CLD] (ss.ShipperID, ss.Customerpart, ss.packQty, COUNT(1))
				--(	SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_LOOP_CLD__REFSerial]	(ss3.SerialNo) 
				--			FROM	@ShippedSerials AS ss3 
				--			WHERE	ss3.PackQty = ss.PackQty 
				--			AND		ss3.Customerpart = ss.Customerpart
				--			AND		ss3.ShipperID = ss.ShipperID 
				--			FOR XML PATH('SEG-REF'), TYPE	
				--		)
				
			FROM @ShippedSerials ss 
			WHERE ss.Customerpart = scp.Customerpart AND ss.ShipperID = scp.ShipperID 
			GROUP BY ss.ShipperID, ss.Customerpart, ss.PackQty 
			FOR XML PATH('LOOP-CLD'), TYPE )
						
			
FROM
	@ShippedCustomerParts  scp
JOIN
	@ShippedSerials ss1 ON ss1.Customerpart = scp.Customerpart AND ss1.ShipperID = scp.ShipperID
GROUP BY
	scp.ID,
	scp.Customerpart,
	scp.ShipperID
ORDER BY
	scp.ID ASC
FOR XML PATH('LOOP-HL')

) +
(SELECT  (SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_INFO_HL]()) ,
		(SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_HL__HierarchicalLevel] (scp.id)),
		(SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_LIN__Buyerpart]( scp.ShipperID, scp.Customerpart )),
		(SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_LIN__QtyShipped]( scp.ShipperID, scp.Customerpart )), 
		(SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_PRF__CustomerPO]( scp.ShipperID, scp.Customerpart )),		
		(SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLItem_SEG_MEA__GrossWeight]( scp.ShipperID, scp.Customerpart )),
		(SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLItem_SEG_MEA__NetWeight]( scp.ShipperID, scp.Customerpart )),
		(SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_LOOP_CLD__CLD] (ss.ShipperID, ss.Customerpart, ss.packQty, COUNT(1))
				--(	SELECT [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_LOOP_CLD__REFSerial]	(ss3.SerialNo) 
				--			FROM	@ShippedSerials AS ss3 
				--			WHERE	ss3.PackQty = ss.PackQty 
				--			AND		ss3.Customerpart = ss.Customerpart
				--			AND		ss3.ShipperID = ss.ShipperID 
				--			FOR XML PATH('SEG-REF'), TYPE	
				--		)
				
			FROM @ShippedSerials ss 
			WHERE ss.Customerpart = scp.Customerpart AND ss.ShipperID = scp.ShipperID 
			GROUP BY ss.ShipperID, ss.Customerpart, ss.PackQty 
			FOR XML PATH('LOOP-CLD'), TYPE )
						
			
FROM
	@ShippedCustomerParts  scp
JOIN
	@ShippedSerials ss1 ON ss1.Customerpart = scp.Customerpart AND ss1.ShipperID = scp.ShipperID
GROUP BY
	scp.ID,
	scp.Customerpart,
	scp.ShipperID
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
