SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE function [EDI].[udf_EDIDocument_DocNumber2]
(
	@XMLData xml
)
returns varchar(30)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/SEG-BSN[1]/DE[@code="0396"][1]', 'varchar(30)')

	if nullif(@ReturnValue,'') is NULL
	Begin
		set @ReturnValue = @XMLData.value('/*[1]/SEG-BGM[1]/CE[@code="C106"][1]/DE[@code="1004"][1]', 'varchar(30)')
	End
	
	if nullif(@ReturnValue,'') is NULL
	Begin
	set @ReturnValue = @XMLData.value('/*[1]/TRN-INFO[1]/@doc_number', 'varchar(30)')
	End

--- </Body>

---	<Return>
	return
		@ReturnValue
end




GO
