SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_LOOP_INFO]
(	
)
RETURNS XML
AS
BEGIN
--- <Body>
	DECLARE
		@outputXML XML

	SET	@outputXML =
	/*	TRN-INFO*/
		(	SELECT	 name='HL LOOP'
			FOR XML RAW ('LOOP-INFO'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END




GO
