SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_LIN__Buyerpart]
(		@ShipperID INT
	,	@CustomerPart VARCHAR(50)
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
				(SELECT [EDIShipNoticeXML_Ford].[udf_SEG_INFO__LIN]())
				
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0350'
					,	[DE!1!name]='ASSIGNED IDENTIFICATION'
					,	[DE!1!type]='AN'
					--,	[DE!1!desc]='Gross Weight'
					,	[DE!1]= ''
					FOR XML EXPLICIT, TYPE
				)

		 ,		(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0235'
					,	[DE!1!name]='PRODUCT/SERVICE ID QUALIFIER'
					,	[DE!1!type]='ID'
					,	[DE!1!desc]='Buyers Part Number'
					,	[DE!1]= 'BP'
					FOR XML EXPLICIT, TYPE
				)
		 ,		(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0234'
					,	[DE!1!name]='PRODUCT/SERVICE ID'
					,	[DE!1!type]='AN'
					--,	[DE!1!desc]='Gross Weight'
					,	[DE!1]= sd.customer_part
					FOR XML EXPLICIT, TYPE
				)
			
				FROM
					shipper_detail sd
				WHERE
					sd.shipper = @ShipperID
				AND
					sd.customer_part = @CustomerPart
			FOR XML RAW ('SEG-LIN'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END
 




GO
