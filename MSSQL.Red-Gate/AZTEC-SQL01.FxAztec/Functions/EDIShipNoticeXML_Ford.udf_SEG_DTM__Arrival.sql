SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_SEG_DTM__Arrival]
(	@ShipperID INT
)
RETURNS XML
AS
BEGIN
--- <Body>
	DECLARE
		 @outputXML XML
		,@ArrivalDate VARCHAR(15)
		,@ArrivalTime VARCHAR(15)

		SELECT @ArrivalDate = CONVERT(CHAR(6), DATEADD(dd,CONVERT(int, ISNULL(NULLIF(id_code_type,''),0)), date_shipped),12) FROM Shipper JOIN edi_setups ON edi_setups.destination = shipper.destination WHERE id = @ShipperID
		SELECT @ArrivalTime = CONVERT(CHAR(2), date_shipped, 108) + SUBSTRING(CONVERT(CHAR(8), date_shipped, 108), 4, 2) FROM Shipper JOIN edi_setups ON edi_setups.destination = shipper.destination WHERE id = @ShipperID

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
					,	[DE!1!desc]= 'Estimated Delivery'
					,	[DE!1]='017'
					FOR XML EXPLICIT, TYPE
			 	)
			/*	DE 0373*/
			,	(	SELECT
						Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0373'
					,	[DE!1!name]='DATE'
					,	[DE!1!type]='DT'
					,	[DE!1]=@ArrivalDate
					FOR XML EXPLICIT, TYPE
			 	)
			/*	DE 0337*/
			,	(	SELECT
						Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0337'
					,	[DE!1!name]='TIME'
					,	[DE!1!type]='TM'
					,	[DE!1]=@ArrivalTime
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
