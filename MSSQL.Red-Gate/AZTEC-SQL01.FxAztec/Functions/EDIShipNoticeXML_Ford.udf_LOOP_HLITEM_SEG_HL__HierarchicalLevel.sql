SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_SEG_HL__HierarchicalLevel]
(		@LineItemID int
)
RETURNS XML
AS
BEGIN
--- <Body>
	DECLARE
		@outputXML XML

	SET	@outputXML =
	/*	SEG-HL*/
		(	SELECT
			/*	SEG-INFO*/
				(SELECT [EDIShipNoticeXML_Ford].[udf_SEG_INFO__HierarchicalLevel]())
				
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0628'
					,	[DE!1!name]='HIERARCHICAL ID NUMBER'
					,	[DE!1!type]='AN'
					--,	[DE!1!desc]='Gross Weight'
					,	[DE!1]= @LineItemID
					FOR XML EXPLICIT, TYPE
				)

		 ,		(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0734'
					,	[DE!1!name]='HIERARCHICAL PARENT ID NUMBER'
					,	[DE!1!type]='AN'
					--,	[DE!1!desc]='Buyers Part Number'
					,	[DE!1]= '1'
					FOR XML EXPLICIT, TYPE
				)
		 ,		(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0735'
					,	[DE!1!name]='HIERARCHICAL LEVEL CODE'
					,	[DE!1!type]='AN'
					,	[DE!1!desc]='Item'
					,	[DE!1]= 'I'
					FOR XML EXPLICIT, TYPE
				)
			
								
			FOR XML RAW ('SEG-HL'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END
 




GO
