SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_LOOP_CLD__CLD]
(		
		@ShipperID INT
	,	@CustomerPart VARCHAR(50)
	,	@PackQty INT
	,	@packCount INT 

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
				(SELECT [EDIShipNoticeXML_Ford].[udf_SEG_INFO_CLD]())
				
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0622'
					,	[DE!1!name]='NUMBER OF LOADS'
					,	[DE!1!type]='N'
					--,	[DE!1!desc]='Gross Weight'
					,	[DE!1]= @packCount
					FOR XML EXPLICIT, TYPE
				)

		 ,		(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0382'
					,	[DE!1!name]='NUMBER OF UNITS SHIPPED'
					,	[DE!1!type]='N'
					--,	[DE!1!desc]='Buyers Part Number'
					,	[DE!1]= @PackQty
					FOR XML EXPLICIT, TYPE
				)
		 ,		(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0103'
					,	[DE!1!name]='PACKAGING CODE'
					,	[DE!1!type]='AN'
					--,	[DE!1!desc]='Gross Weight'
					,	[DE!1]= 'CNT90'
					FOR XML EXPLICIT, TYPE
				)
			
			FOR XML RAW ('SEG-CLD'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END
 











GO
