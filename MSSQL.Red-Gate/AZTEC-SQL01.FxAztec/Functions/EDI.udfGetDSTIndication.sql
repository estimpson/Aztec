SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create FUNCTION [EDI].[udfGetDSTIndication] (
@datToCheck datetime
) RETURNS varchar(10)
AS 
BEGIN 

DECLARE @datLocalDateTime datetime

DECLARE @intYear integer
DECLARE @strMar1 varchar(18)
DECLARE @strNov1 varchar(18)
DECLARE @DayOfTheWeek integer
DECLARE @DateDifference integer
DECLARE @datDSTStarts datetime
DECLARE @datDSTEnds datetime
DECLARE @intGMTOffset integer
DECLARE @DSTEvaluation varchar(10)

/* Calculate when DST begins for the year in question */
SET @intYear = DATEPART(yyyy, @datToCheck);
SET @strMar1 = CONVERT(varchar(18), @intYear) + '0301 02:00:00';
SET @DayOfTheWeek = DATEPART(dw, @strMar1);	/* Day Mar 1 falls on in that year */
SET @DateDifference = (CASE WHEN @DayOfTheWeek = 1 THEN 0 ELSE 8 - @DayOfTheWeek END);	/* # of days between that day and the following Sunday ("the first Sunday in Mar")*/
SET @datDSTStarts = DATEADD(dd, @DateDifference, @strMar1);/*Return 1st Sunday in March*/
SET @datDSTStarts = DATEADD(wk, 1, @datDSTStarts);/*Return 2nd Sunday in March*/

/* Calculate when DST is over for the year in question */
SET @strNov1 = CONVERT(varchar(18), @intYear) + '1101 02:00:00';
SET @DayOfTheWeek = DATEPART(dw, @strNov1);	/* Day Nov 1 falls on in that year */
SET @DateDifference = (CASE WHEN @DayOfTheWeek = 1 THEN 0 ELSE 8 - @DayOfTheWeek END);	
SET @datDSTEnds = DATEADD(dd, @DateDifference, @strNov1);

/* Determine if the date in question is in DST or not */
IF @datToCheck BETWEEN @datDSTStarts AND @datDSTEnds
SET  @DSTEvaluation = 'ED'
ELSE
SET  @DSTEvaluation = 'ET'

RETURN @DSTEvaluation

END
GO
