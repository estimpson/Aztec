SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_LOOP_HLShipment_SEG_MEA__CompositeUMLB]
(	@ShipperID INT
)
RETURNS XML
AS
BEGIN
--- <Body>
	DECLARE
		@outputXML XML

	SET	@outputXML =

(SELECT	 CE.code 
		,CE.name
		,	(	SELECT
						Tag=1
					,	Parent=NULL
			 		,	[DE!1!code]='0355'
					,	[DE!1!name]=''
					,	[DE!1!type]=''
					,	[DE!1]='LB'
					FOR XML EXPLICIT, TYPE
			 	)
   FROM 
	(SELECT code =  'C001', name = 'COMPOSITE UNIT OF MEASURE' ) as CE


FOR XML AUTO
)

--- </Body>

---	<Return>
	RETURN
		@outputXML
END
 --Select [EDIShipNoticeXML_Ford].[udf_LOOP_HLShipment_SEG_MEA__CompositeUMLB] (1062979)



GO
