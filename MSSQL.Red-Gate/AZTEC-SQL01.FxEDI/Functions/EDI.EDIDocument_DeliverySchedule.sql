SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [EDI].[EDIDocument_DeliverySchedule]
(	@XMLData xml
)
returns varchar(10)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/SEG-BGM[1]/CE[@code="C002"][1]/DE[@code="1001"][1]', 'varchar(8)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end
GO
