SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_LOOP_HLITEM_LOOP_CLD__REFSerial]
(		@SerialNo INT
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
				(SELECT [EDIShipNoticeXML_Ford].[udf_SEG_INFO__REF]())
				
			,	(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0128'
					,	[DE!1!name]='REFERENCE IDENTIFICATION QUALIFIER'
					,	[DE!1!type]='ID'
					,	[DE!1!desc]='Bar-Coded Serial Number'
					,	[DE!1]= 'LS'
					FOR XML EXPLICIT, TYPE
				)

		 ,		(	SELECT
					 	Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0127'
					,	[DE!1!name]='REFERENCE IDENTIFICATION'
					,	[DE!1!type]='AN'
					--,	[DE!1!desc]='Buyers Part Number'
					,	[DE!1]= @SerialNo
					FOR XML EXPLICIT, TYPE
				)
		 
			
			FOR XML RAW ('SEG-REF'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END
 





GO
