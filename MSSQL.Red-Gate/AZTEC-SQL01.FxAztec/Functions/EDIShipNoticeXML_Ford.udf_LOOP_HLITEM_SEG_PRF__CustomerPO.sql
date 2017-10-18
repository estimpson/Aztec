SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_PRF__CustomerPO]
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
				(SELECT [EDIShipNoticeXML_Ford].[udf_SEG_INFO__PRF]())
				
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0324'
					,	[DE!1!name]='PURCHASE ORDER NUMBER'
					,	[DE!1!type]='AN'
					--,	[DE!1!desc]='Gross Weight'
					,	[DE!1]= MAX(sd.customer_po)
					FOR XML EXPLICIT, TYPE
				)
			
				FROM
					shipper_detail sd
				WHERE
					sd.shipper = @ShipperID
				AND
					sd.customer_part = @CustomerPart
				GROUP BY
					sd.customer_po
			FOR XML RAW ('SEG-PRF'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END
 




GO
