SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_LOOP_HLShipment_SEG_TD5__Carrier]
(	@ShipperID INT
)
RETURNS XML
AS
BEGIN
--- <Body>
	DECLARE
		@outputXML XML

	SET	@outputXML =
	/*	SEG-TD5*/
		(	SELECT
			/*	SEG-INFO*/
				(	SELECT
						code='TD5'
					,	name='CARRIER DETAILS (ROUTING SEQUENCE/TRANS'
					FOR XML RAW ('SEG-INFO'), TYPE
				)
			/*	DE 0133*/
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0133'
					,	[DE!1!name]='ROUTING SEQUENCE CODE'
					,	[DE!1!type]='ID'
					,	[DE!1!desc]='Origin/Delivery Carrier (Any Mode)'
					,	[DE!1]='B'
					FOR XML EXPLICIT, TYPE
			 	)
			/*	DE 0066*/
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0066'
					,	[DE!1!name]='IDENTIFICATION CODE QUALIFIER'
					,	[DE!1!type]='ID'
					--,	[DE!1!desc]='Gross Weight'
					,	[DE!1]= '02'
					FOR XML EXPLICIT, TYPE
			 	)
			/*	DE 0067*/
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0067'
					,	[DE!1!name]='IDENTIFICATION CODE'
					,	[DE!1!type]='AN'
					--,	[DE!1!desc]='Gross Weight'
					,	[DE!1]= LEFT(COALESCE(NULLIF(d.address_5,'') ,s.ship_via, 'PSKL'),4)
					FOR XML EXPLICIT, TYPE
			 	)

			/*	DE 0091*/
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0091'
					,	[DE!1!name]='TRANSPORTATION METHOD/TYPE CODE'
					,	[DE!1!type]='ID'
					--,	[DE!1!desc]='Gross Weight'
					,	[DE!1]= COALESCE((CASE WHEN ship_via ='NLMI' AND  s.trans_mode ='C' THEN '' ELSE s.trans_mode END) , 'C')
					FOR XML EXPLICIT, TYPE
			 	)
			/*	DE 0387*/
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0387'
					,	[DE!1!name]='ROUTING'
					,	[DE!1!type]='AN'
					--,	[DE!1!desc]='Gross Weight'
					--,	[DE!1]= COALESCE((CASE WHEN ship_via ='NLMI' and  shipper_trans_mode ='C' THEN '' ELSE shipper_trans_mode END) , 'C')
					FOR XML EXPLICIT, TYPE
			 	)
			/*	DE 0368*/
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0368'
					,	[DE!1!name]='SHIPMENT/ORDER STATUS CODE'
					,	[DE!1!type]='ID'
					--,	[DE!1!desc]='Gross Weight'
					--,	[DE!1]= COALESCE((CASE WHEN ship_via ='NLMI' and  shipper_trans_mode ='C' THEN '' ELSE shipper_trans_mode END) , 'C')
					FOR XML EXPLICIT, TYPE
			 	)
				/*	DE 0309*/
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0309'
					,	[DE!1!name]='LOCATION QUALIFIER'
					,	[DE!1!type]='ID'
					,	[DE!1!desc]='Pool Point'
					,	[DE!1]= COALESCE((CASE WHEN s.trans_mode LIKE 'A%' THEN 'OR' WHEN s.trans_mode = 'E' THEN '' WHEN es.pool_code IS NOT NULL THEN 'PP' ELSE '' END) , '')
					FOR XML EXPLICIT, TYPE
			 	)
				/*	DE 0310*/
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0310'
					,	[DE!1!name]='LOCATION IDENTIFIER'
					,	[DE!1!type]='AN'
					--,	[DE!1!desc]='Pool Point'
					,	[DE!1]= COALESCE((CASE WHEN s.trans_mode LIKE 'A%' THEN 'DTW' WHEN s.trans_mode = 'E' THEN '' WHEN es.pool_code IS NOT NULL THEN es.pool_code ELSE '' END) , '')
					FOR XML EXPLICIT, TYPE
			 	)
			
			
				FROM
					shipper s
				JOIN
					destination d ON d.destination = s.destination
				JOIN
					edi_setups es ON es.destination = d.destination
				WHERE
					s.id = @ShipperID
			FOR XML RAW ('SEG-TD5'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END
 --Select [EDIShipNoticeXML_Ford].[udf_LOOP_HLShipment_SEG_TD5__Carrier] (1062979)






GO
