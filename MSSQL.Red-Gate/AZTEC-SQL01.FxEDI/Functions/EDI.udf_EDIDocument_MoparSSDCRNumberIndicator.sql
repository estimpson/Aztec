SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [EDI].[udf_EDIDocument_MoparSSDCRNumberIndicator]
(
	@XMLData XML
)
RETURNS INTEGER
AS
BEGIN
--- <Body>
	DECLARE
		@ReturnValue INTEGER
		
	SET @ReturnValue = CASE WHEN @XMLData.value	('(	for $a in *[1]/LOOP-LIN/SEG-LIN/DE[@code="0235"] where $a="CR" return $a/../DE[. >> $a][@code="0234"][1])[1]', 'varchar(30)') IS NOT NULL THEN 1 ELSE 0 END
--- </Body>

---	<Return>
	RETURN
		@ReturnValue
END


GO
