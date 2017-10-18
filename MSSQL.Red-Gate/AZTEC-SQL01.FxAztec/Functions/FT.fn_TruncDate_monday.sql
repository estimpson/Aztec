SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create function [FT].[fn_TruncDate_monday]
(	@DatePart nvarchar (25),
	@ArgDT datetime)
returns datetime
begin
	declare @ReturnDT datetime
	set	@ReturnDT = ft.fn_DateAdd (@DatePart, FT.fn_DateDiff (@DatePart, '1996-01-01', (CASE WHEN datepart (weekday, @ArgDT) = 1 and @DatePart in ('w', 'wk' )THEN dateadd(wk,-1, @ArgDT) ELSE @ArgDT END)), '1996-01-01')
	return	@ReturnDT
end
GO
