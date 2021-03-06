SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_LIN__QtyShipped_RC]
(		@QtyShipped INT
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
				(SELECT [EDIShipNoticeXML_Ford].[udf_SEG_INFO__SN1]())
				
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
			 		,	[DE!1!code]='0382'
					,	[DE!1!name]='NUMBER OF UNITS SHIPPED'
					,	[DE!1!type]='N'
					--,	[DE!1!desc]=''
					,	[DE!1]= @QtyShipped
					FOR XML EXPLICIT, TYPE
				)
		 ,		(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0355'
					,	[DE!1!name]='UNIT OR BASIS FOR MEASUREMENT CODE'
					,	[DE!1!type]='ID'
					,	[DE!1!desc]='Each'
					,	[DE!1]= 'EA'
					FOR XML EXPLICIT, TYPE
				)
			 ,		(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0646'
					,	[DE!1!name]='QUANTITY SHIPPED TO DATE'
					,	[DE!1!type]='N'
					--,	[DE!1!desc]=''
					,	[DE!1]= @QtyShipped
					FOR XML EXPLICIT, TYPE
				)
			
				
			FOR XML RAW ('SEG-SN1'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END
 





GO
