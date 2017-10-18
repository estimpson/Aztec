SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_SEG_DTM__Shipped]
(	@ShipperID INT
)
RETURNS XML
AS
BEGIN
--- <Body>
	DECLARE
		 @outputXML XML
		,@ShippedDate VARCHAR(15)
		,@ShippedTime VARCHAR(15)

		SELECT @ShippedDate = CONVERT(CHAR(6), date_shipped, 12) FROM Shipper WHERE id = @ShipperID
		SELECT @ShippedTime = CONVERT(CHAR(2), date_shipped, 108) + SUBSTRING(CONVERT(CHAR(8), date_shipped, 108), 4, 2) FROM Shipper WHERE id = @ShipperID

	SET	@outputXML =
	/*	SEG-DTM*/
		(	SELECT
			/*	SEG-INFO*/
				(	SELECT
						code='DTM'
					,	name='DATE/TIME REFERENCE'
					FOR XML RAW ('SEG-INFO'), TYPE
				)
			/*	DE 0374*/
			,	(	SELECT
						Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0374'
					,	[DE!1!name]='DATE/TIME QUALIFIER'
					,	[DE!1!type]='ID'
					,	[DE!1!desc]= 'Shipped'
					,	[DE!1]='011'
					FOR XML EXPLICIT, TYPE
			 	)
			/*	DE 0373*/
			,	(	SELECT
						Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0373'
					,	[DE!1!name]='DATE'
					,	[DE!1!type]='DT'
					,	[DE!1]=@ShippedDate
					FOR XML EXPLICIT, TYPE
			 	)
			/*	DE 0337*/
			,	(	SELECT
						Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0337'
					,	[DE!1!name]='TIME'
					,	[DE!1!type]='TM'
					,	[DE!1]=@ShippedTime
					FOR XML EXPLICIT, TYPE
			 	)
			FOR XML RAW ('SEG-DTM'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END





GO
