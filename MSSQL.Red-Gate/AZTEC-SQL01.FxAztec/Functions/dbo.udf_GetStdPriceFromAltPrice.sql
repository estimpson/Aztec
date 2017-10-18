SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[udf_GetStdPriceFromAltPrice]
(
	@Part varchar(25)
,	@AltPrice numeric(20,6)
,	@AlternateCurrency varchar(3)
)
returns numeric(20,6)
as
begin
--- <Body>
	/*	Convert standard to unit quantity. */
	declare
		@StdPrice numeric(20,6)
	
	set	@StdPrice = @AltPrice

--- </Body>

---	<Return>
	return
		@StdPrice
end

GO
