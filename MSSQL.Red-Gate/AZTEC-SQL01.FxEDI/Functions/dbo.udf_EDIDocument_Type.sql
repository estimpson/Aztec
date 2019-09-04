SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [dbo].[udf_EDIDocument_Type]
(
	@XMLData xml
)
returns varchar(6)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('*[1]/TRN-INFO[1]/@type', 'varchar(6)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end


GO
