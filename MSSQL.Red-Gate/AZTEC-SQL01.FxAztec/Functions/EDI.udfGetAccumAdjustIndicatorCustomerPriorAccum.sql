SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [EDI].[udfGetAccumAdjustIndicatorCustomerPriorAccum] (
@OurAccum NUMERIC(20,6), @CustomerPriorAccum NUMERIC(20,6)
) RETURNS INT
AS 
BEGIN 

--Select [EDI].[udfGetAccumAdjustIndicatorCustomerPriorAccum] ( 100,0)

DECLARE @AccumAdjustIndicator INT,
		@AccumCalculation NUMERIC (20,6)

IF COALESCE(@OurAccum,0) = COALESCE(@CustomerPriorAccum,0)
	BEGIN
	SELECT @AccumAdjustIndicator = 0
	
	END
 
IF COALESCE(@OurAccum,0.00000) = 0.000000 AND COALESCE(@CustomerPriorAccum,0.000000) != 0.000000
	BEGIN
	SELECT @AccumAdjustIndicator = 0
	
	END

IF COALESCE(@OurAccum,0.000000) != 0.000000 AND (COALESCE(@OurAccum,0) != COALESCE(@CustomerPriorAccum,0))
	BEGIN

	SELECT @AccumCalculation = (@OurAccum - @CustomerPriorAccum)/@OurAccum
	 IF ABS(@AccumCalculation) > .10
		SELECT @AccumAdjustIndicator = 0
		ELSE
		SELECT @AccumAdjustIndicator = 1
	
	
	END

RETURN @AccumAdjustIndicator


END


GO
