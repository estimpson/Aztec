SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE FUNCTION [EDIShipNoticeXML_Ford].[udf_SEG_INFO__HierarchicalLevel]
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
		(	SELECT	code = 'HL' 
					,name='HIERARCHICAL LEVEL'
			FOR XML RAW ('SEG-INFO'), TYPE
		)
--- </Body>

---	<Return>
	RETURN
		@outputXML
END






GO
