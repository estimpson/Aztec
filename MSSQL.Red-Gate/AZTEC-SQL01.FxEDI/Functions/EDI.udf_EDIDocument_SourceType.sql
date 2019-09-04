SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [EDI].[udf_EDIDocument_SourceType]
(
	@XMLData XML
)
RETURNS VARCHAR(50)
AS
BEGIN
--- <Body>
	DECLARE
		@ReturnValue VARCHAR(MAX)
		
	SET @ReturnValue = @XMLData.value('/*[1]/TRN-INFO[1]/@source-type', 'varchar(50)')
--- </Body>

---	<Return>
	RETURN
		@ReturnValue
END


GO
