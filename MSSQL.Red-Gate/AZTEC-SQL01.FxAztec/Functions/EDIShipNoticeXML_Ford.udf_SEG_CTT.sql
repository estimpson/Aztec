SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_SEG_CTT]
(	@ShipperID INT
)
RETURNS XML
AS
BEGIN
--- <Body>
	DECLARE
		@outputXML XML

	SET	@outputXML =
	/*	SEG-CTT*/
		(	SELECT
			/*	SEG-INFO*/
				(	SELECT
						code='CTT'
					,	name='TRANSACTION TOTALS'
					FOR XML RAW ('SEG-INFO'), TYPE
				)
			/*	DE 0354*/
			,	(	SELECT
						Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0354'
					,	[DE!1!name]='NUMBER OF LINE ITEMS'
					,	[DE!1!type]='N'
					,	[DE!1]=COUNT(1)+1
					FROM
						dbo.shipper_detail sd2
						WHERE sd2.shipper = sd.id
					FOR XML EXPLICIT, TYPE
			 	)
			/*	DE 0347*/
			,	(	SELECT
						Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0347'
					,	[DE!1!name]='HASH TOTAL'
					,	[DE!1!type]='N'
					--,	[DE!1!desc]='Total On Order Quantity'
					,	[DE!1]=SUM(sd3.qty_packed)
					FROM
						dbo.shipper_detail sd3
						WHERE sd3.shipper = sd.id
					FOR XML EXPLICIT, TYPE
			 	)
			FROM
				dbo.shipper sd
			WHERE
				sd.id = @ShipperID
			
			FOR XML RAW ('SEG-CTT'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END




GO
