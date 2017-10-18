SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [EDI].[udf_EDIDocument_MessageNumber]
(
	@XMLData xml
)
returns varchar(30)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/SEG-BGM[1]/CE[@code="C106"][1]/DE[@code="1004"][1]', 'varchar(30)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end
GO
