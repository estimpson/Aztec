SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_ShipNotice_LOOP_HL__Shipment]
(	@ShipperID INT
)
RETURNS XML
AS
BEGIN
--- <Body>
	DECLARE
		@outputXML XML

	SET	@outputXML =
	/*	LOOP-HL*/
		(	SELECT
			/*	LOOP-INFO*/
				(	SELECT
						name='HL Loop'
					FOR XML RAW ('LOOP-INFO'), TYPE
				)
			/*	LOOP-HL*/
			,	(	SELECT
					/*	SEG-INFO*/
						(	SELECT
								code='HL'
							,	name='HIERARCHICAL LEVEL'
							FOR XML RAW ('SEG-INFO'), TYPE
						)
					/*	DE 0628*/
					,	(	SELECT
								Tag=1
							,	Parent=NULL
			 				,	[DE!1!code]='0628'
							,	[DE!1!name]='HIERARCHICAL ID NUMBER'
							,	[DE!1!type]='AN'
							,	[DE!1]='1'
							FOR XML EXPLICIT, TYPE
			 			)
					/*	DE 0734*/
					,	(	SELECT
								Tag=1
							,	Parent=NULL
			 				,	[DE!1!code]='0734'
							,	[DE!1!name]='HIERARCHICAL PARENT ID NUMBER'
							,	[DE!1!type]='AN'
							FOR XML EXPLICIT, TYPE
			 			)
					/*	DE 0735*/
					,	(	SELECT
								Tag=1
							,	Parent=NULL
			 				,	[DE!1!code]='0735'
							,	[DE!1!name]='HIERARCHICAL LEVEL CODE'
							,	[DE!1!type]='ID'
							,	[DE!1!desc]='Shipment'
							,	[DE!1]='S'
							FOR XML EXPLICIT, TYPE
			 			)
					
					FOR XML RAW ('SEG-HL'), TYPE
				)
			
			,	EDIShipNoticeXML_Ford.udf_LOOP_HLShipment_SEG_MEA__GrossWeight(@ShipperID)
			,	EDIShipNoticeXML_Ford.udf_LOOP_HLShipment_SEG_MEA__NetWeight(@ShipperID)
			,	EDIShipNoticeXML_Ford.udf_LOOP_HLShipment_SEG_TD1__Packaging(@ShipperID)
			,	EDIShipNoticeXML_Ford.udf_LOOP_HLShipment_SEG_TD5__Carrier(@ShipperID)
			,	EDIShipNoticeXML_Ford.udf_ShipNotice_LOOP_TD3__Conveyance(@ShipperID)
			,	EDIShipNoticeXML_Ford.udf_LOOP_HLShipment_SEG_REF__BillOflading(@ShipperID)
			,	EDIShipNoticeXML_Ford.udf_LOOP_HLShipment_SEG_REF__PackingList(@ShipperID)
			,	EDIShipNoticeXML_Ford.udf_LOOP_HLShipment_SEG_REF__AirWaybill(@ShipperID)
			,	EDIShipNoticeXML_Ford.udf_ShipNotice_LOOP_N1__ShipToCode(@ShipperID)			
			,	EDIShipNoticeXML_Ford.udf_ShipNotice_LOOP_N1__ShipFromCode(@ShipperID)
			,	EDIShipNoticeXML_Ford.udf_ShipNotice_LOOP_N1__SupplierCode(@ShipperID)
			FOR XML RAW ('LOOP-HL'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END





GO
