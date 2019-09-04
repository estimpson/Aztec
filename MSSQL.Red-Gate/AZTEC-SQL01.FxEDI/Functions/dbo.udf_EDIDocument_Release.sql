SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE function [dbo].[udf_EDIDocument_Release]
(
	@XMLData xml
)
returns varchar(12)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/TRN-INFO[1]/@Release', 'varchar(12)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end




GO
