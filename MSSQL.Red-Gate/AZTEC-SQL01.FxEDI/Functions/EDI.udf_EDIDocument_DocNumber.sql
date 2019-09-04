SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [EDI].[udf_EDIDocument_DocNumber]
(
	@XMLData xml
)
returns varchar(50)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/TRN-INFO[1]/@doc_number', 'varchar(50)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end


GO
