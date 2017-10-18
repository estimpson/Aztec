SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [FT].[fn_DateAdd]
(	@DatePart varchar (9)
,	@ArgNum integer
,	@ArgDT datetime)
returns	datetime
begin
--- <Body>
	declare @ReturnDT datetime
	set	@ReturnDT =
		case	when @DatePart in ('Year', 'yy', 'yyyy') then
				dateadd (year, @ArgNum, @ArgDT)
			when @DatePart in ('Quarter', 'qq', 'q') then
				dateadd (quarter, @ArgNum, @ArgDT)
			when @DatePart in ('Month', 'mm', 'm') then
				dateadd (month, @ArgNum, @ArgDT)
			when @DatePart in ('DayofYear', 'dy', 'y') then
				dateadd (dayofyear, @ArgNum, @ArgDT)
			when @DatePart in ('Day', 'dd', 'd') then
				dateadd (day, @ArgNum, @ArgDT)
			when @DatePart in ('Week', 'wk', 'ww') then
				dateadd (week, @ArgNum, @ArgDT)
			when @DatePart in ('Hour', 'hh') then
				dateadd (hour, @ArgNum, @ArgDT)
			when @DatePart in ('Minute', 'mi', 'n') then
				dateadd (minute, @ArgNum, @ArgDT)
			when @DatePart in ('Second', 'ss', 's') then
				dateadd (second, @ArgNum, @ArgDT)
			when @DatePart in ('Millisecond', 'ms') then
				dateadd (millisecond, @ArgNum, @ArgDT)
		end
--- </Body>

---	<Return>
	return	@ReturnDT
end
GO
