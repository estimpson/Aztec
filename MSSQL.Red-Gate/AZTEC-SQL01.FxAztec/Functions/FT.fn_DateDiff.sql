SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [FT].[fn_DateDiff]
(	@DatePart varchar (9),
	@StartDT datetime,
	@EndDT datetime)
returns	integer
begin
--- <Body>
	declare @Return integer
	set	@Return =
		case	when @DatePart in ('Year', 'yy', 'yyyy') then
				datediff (year, @StartDT, @EndDT)
			when @DatePart in ('Quarter', 'qq', 'q') then
				datediff (quarter, @StartDT, @EndDT)
			when @DatePart in ('Month', 'mm', 'm') then
				datediff (month, @StartDT, @EndDT)
			when @DatePart in ('DayofYear', 'dy', 'y') then
				datediff (dayofyear, @StartDT, @EndDT)
			when @DatePart in ('Day', 'dd', 'd') then
				datediff (day, @StartDT, @EndDT)
			when @DatePart in ('Week', 'wk', 'ww') then
				datediff (week, @StartDT, @EndDT)
			when @DatePart in ('Hour', 'hh') then
				datediff (hour, @StartDT, @EndDT)
			when @DatePart in ('Minute', 'mi', 'n') then
				datediff (minute, @StartDT, @EndDT)
			when @DatePart in ('Second', 'ss', 's') then
				datediff (second, @StartDT, @EndDT)
			when @DatePart in ('Millisecond', 'ms') then
				datediff (millisecond, @StartDT, @EndDT)
		end
--- </Body>

---	<Return>
	return	@Return
end
GO
