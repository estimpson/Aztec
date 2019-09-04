SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI].[EDIDocument_Release]
(	@XMLData xml
)
returns varchar(10)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/TRN-INFO[1]/@doc_number', 'varchar(25)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end
GO
