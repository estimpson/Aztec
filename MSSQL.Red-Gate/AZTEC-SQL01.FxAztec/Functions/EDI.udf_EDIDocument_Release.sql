SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [EDI].[udf_EDIDocument_Release]
(
	@XMLData xml
)
returns varchar(30)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/SEG-BGM[1]/CE[@code="C002"][1]/DE[@code="1001"][1]', 'varchar(30)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end
GO
