SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE function [dbo].[udf_GetAltPriceFromStdPrice]
(
	@Part varchar(25)
,	@StdPrice numeric(20,6)
,	@AlternateCurrency varchar(3)
)
returns numeric(20,6)
as
begin
--- <Body>
	/*	Convert standard to unit quantity. */
	declare
		@AltPrice numeric(20,6)
	
	set	@AltPrice = @StdPrice

--- </Body>

---	<Return>
	return
		@AltPrice
end

GO
