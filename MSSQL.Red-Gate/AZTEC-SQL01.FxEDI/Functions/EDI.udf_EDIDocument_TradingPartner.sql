SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE function [EDI].[udf_EDIDocument_TradingPartner]
(
	@XMLData xml
)
returns varchar(50)
as
begin
--- <Body>
	declare
		@ReturnValue varchar(max)
		
	set @ReturnValue = @XMLData.value('/*[1]/TRN-INFO[1]/@trading_partner', 'varchar(50)')
--- </Body>

---	<Return>
	return
		@ReturnValue
end



GO
