SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_LOOP_HLItem_SEG_MEA__GrossWeight]
(	@ShipperID INT
	,@CustomerPart VARCHAR(50)
)
RETURNS XML
AS
BEGIN
--- <Body>
	DECLARE
		@outputXML XML

	SET	@outputXML =
	/*	SEG-ATH*/
		(	SELECT
			/*	SEG-INFO*/
				(	SELECT
						code='MEA'
					,	name='MEASUREMENTS'
					FOR XML RAW ('SEG-INFO'), TYPE
				)
			/*	DE 0737*/
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0737'
					,	[DE!1!name]='MEASUREMENT REFERENCE ID CODE'
					,	[DE!1!type]='ID'
					,	[DE!1!desc]='Physical Dimensions'
					,	[DE!1]='PD'
					FOR XML EXPLICIT, TYPE
			 	)
			/*	DE 0738*/
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0738'
					,	[DE!1!name]='MEASUREMENT QUALIFIER'
					,	[DE!1!type]='ID'
					,	[DE!1!desc]='Gross Weight'
					,	[DE!1]='G'
					FOR XML EXPLICIT, TYPE
			 	)
			/*	DE 0739*/
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0739'
					,	[DE!1!name]='MEASUREMENT VALUE'
					,	[DE!1!type]='N'
					,	[DE!1]= CONVERT(INT,SUM(sd.gross_weight))
					FOR XML EXPLICIT, TYPE

			 	)
			, (	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0355'
					,	[DE!1!name]='UNIT OF MEASUREMENT CODE'
					,	[DE!1!type]='ID'
					,	[DE!1]= 'LB'
					FOR XML EXPLICIT, TYPE

			 	)
			
				FROM
					shipper_detail sd
				WHERE
					sd.shipper = @ShipperID AND
					sd.customer_part = @CustomerPart
			FOR XML RAW ('SEG-MEA'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END
 --Select [EDIShipNoticeXML_Ford].[udf_LOOP_HLItem_SEG_MEA__GrossWeight] (1062979)





GO
