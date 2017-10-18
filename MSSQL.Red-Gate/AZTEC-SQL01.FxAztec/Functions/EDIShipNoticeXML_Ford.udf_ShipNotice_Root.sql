SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_ShipNotice_Root]
(	@ShipperID INT
,	@Purpose CHAR(2)
,	@PartialComplete INT

)
RETURNS XML
AS
BEGIN
-- Select [EDIShipNoticeXML_Ford].[udf_ShipNotice_Root](1063429,'00',2)
--- <Body>
	DECLARE
		@outputXML XML

	SET	@outputXML =
	/*	TRN-856*/
		(	SELECT
				EDIShipNoticeXML_Ford.udf_TRN_INFO(@ShipperID,@PartialComplete)
			,	EDIShipNoticeXML_Ford.udf_SEG_BSN(@ShipperID, @Purpose)
			,	EDIShipNoticeXML_Ford.udf_SEG_DTM__Shipped(@ShipperID)
			,	EDIShipNoticeXML_Ford.udf_SEG_DTM__Arrival(@ShipperID)
			,	EDIShipNoticeXML_Ford.udf_ShipNotice_LOOP_HL__Shipment(@ShipperID)
			,	EDIShipNoticeXML_Ford.udf_ShipNotice_LOOP_HL__Item_wRC (@ShipperID)
			,	EDIShipNoticeXML_Ford.udf_SEG_CTT (@ShipperID)
			FOR XML RAW ('TRN-856'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END










GO
