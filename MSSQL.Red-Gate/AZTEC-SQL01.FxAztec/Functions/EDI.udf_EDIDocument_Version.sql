SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [EDI].[udf_EDIDocument_Version]
(
	@XMLData xml
)
returns varchar(10)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/TRN-INFO[1]/@version', 'varchar(10)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end
GO
