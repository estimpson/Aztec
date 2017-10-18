SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_SEG_BSN]
(	@ShipperID INT,
	@Purpose CHAR(2)
)
RETURNS XML
AS
BEGIN
--- <Body>
	DECLARE
		 @outputXML XML
		,@ASNDate VARCHAR(15)
		,@ASNTime VARCHAR(15)

		SELECT @ASNDate = CONVERT(CHAR(6), GETDATE(), 12)
		SELECT @ASNTime = CONVERT(CHAR(2), GETDATE(), 108) + SUBSTRING(CONVERT(CHAR(8), GETDATE(), 108), 4, 2)

	SET	@outputXML =
	/*	SEG-BSN*/
		(	SELECT
			/*	SEG-INFO*/
				(	SELECT
						code='BSN'
					,	name='BEGINNING SEGMENT FOR SHIP NOTICE'
					FOR XML RAW ('SEG-INFO'), TYPE
				)
			/*	DE 0353*/
			,	(	SELECT
						Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0353'
					,	[DE!1!name]='TRANSACTION SET PURPOSE CODE'
					,	[DE!1!type]='ID'
					,	[DE!1!desc]= CASE @Purpose WHEN '00' THEN 'Original' ELSE 'Original' END
					,	[DE!1]=@Purpose
					FOR XML EXPLICIT, TYPE
			 	)
			/*	DE 0396*/
			,	(	SELECT
						Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0396'
					,	[DE!1!name]='SHIPMENT IDENTIFICATION'
					,	[DE!1!type]='AN'
					,	[DE!1]=@ShipperID
					FOR XML EXPLICIT, TYPE
			 	)
			/*	DE 0373*/
			,	(	SELECT
						Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0373'
					,	[DE!1!name]='DATE'
					,	[DE!1!type]='DT'
					,	[DE!1]=@ASNDate
					FOR XML EXPLICIT, TYPE
			 	)
		/*	DE 0337*/
			,	(	SELECT
						Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0337'
					,	[DE!1!name]='TIME'
					,	[DE!1!type]='TM'
					,	[DE!1]=@ASNTime
					FOR XML EXPLICIT, TYPE
			 	)
			FOR XML RAW ('SEG-BSN'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END




GO
