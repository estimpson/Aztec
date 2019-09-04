SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [EDI].[udf_EDIDocument_Version]
(	@XMLData xml
)
returns varchar(20)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/TRN-INFO[1]/@version', 'varchar(20)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end


GO
