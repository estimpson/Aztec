SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [FT].[udf_NumberFromMaskAndValue]
(	@NumberMask varchar(50)
,	@Value bigint
,	@TranDT datetime)
returns
	varchar(50)
as
--	Mask definition:
--		Mask	Interpretation
--		#		0-9, digit not written if unnecessary
--		0		0-9, digit always written
--		[A-Z]	Literal
--		dd		two-digit day of month
--		#d		one or two-digit day of month
--		ddd		three-digit day of the year
--		##d		one, two, or three-digit day of year
--		mm		two-digit month
--		#m		one or two-digit month
--		yy		two-digit year
--		yyyy	four-digit year
--
--	Mask is interpreted from right to left.
--	Any invalid mask (i.e. 'yyy') is treated as literal (i.e. 'y09').

begin
	declare @CharI int; set @CharI = len(@NumberMask)
	declare @MaskChar char(1)
	declare	@CurrentCommand varchar(4)
	declare @ReverseNumber varchar(50); set @ReverseNumber = ''
	declare	@Number varchar(50)
	
	while	@CharI > 0 begin
		set	@MaskChar = substring(@NumberMask, @CharI, 1)
		if	@MaskChar = '#' and @Value = 0 begin
			set	@CharI = @CharI - 1
		end
		else if	@MaskChar = '#' or @MaskChar = '0' begin
			
			set @ReverseNumber = @ReverseNumber + convert(char(1), @Value % 10)
			set @Value = floor(@Value / 10)
			set	@CharI = @CharI - 1
		end
		else if	@MaskChar = 'y' and substring(@NumberMask, @CharI - 3, 4) = 'yyyy' begin
			set @ReverseNumber = @ReverseNumber + reverse(convert(char(4), datepart(year, @TranDT)))
			set	@CharI = @CharI - 4
		end
		else if	@MaskChar = 'y' and substring(@NumberMask, @CharI - 1, 2) = 'yy' begin
			set @ReverseNumber = @ReverseNumber + reverse(right(convert(char(4), datepart(year, @TranDT)), 2))
			set	@CharI = @CharI - 2
		end
		else if	@MaskChar = 'm' and substring(@NumberMask, @CharI - 1, 2) = 'mm' begin
			set @ReverseNumber = @ReverseNumber + reverse(right('0' + convert(varchar(2), datepart(month, @TranDT)), 2))
			set	@CharI = @CharI - 2
		end
		else if	@MaskChar = 'm' and substring(@NumberMask, @CharI - 1, 2) = '#m' begin
			set @ReverseNumber = @ReverseNumber + reverse(convert(varchar(2), datepart(month, @TranDT)))
			set	@CharI = @CharI - 2
		end
		else if	@MaskChar = 'd' and substring(@NumberMask, @CharI - 2, 3) = 'ddd' begin
			set @ReverseNumber = @ReverseNumber + reverse(right('00' + convert(varchar(3), datepart(dy, @TranDT)), 3))
			set	@CharI = @CharI - 3
		end
		else if	@MaskChar = 'd' and substring(@NumberMask, @CharI - 2, 3) = '##d' begin
			set @ReverseNumber = @ReverseNumber + reverse(convert(varchar(3), datepart(dy, @TranDT)))
			set	@CharI = @CharI - 3
		end
		else if	@MaskChar = 'd' and substring(@NumberMask, @CharI - 1, 2) = 'dd' begin
			set @ReverseNumber = @ReverseNumber + reverse(right('0' + convert(varchar(2), datepart(day, @TranDT)), 2))
			set	@CharI = @CharI - 2
		end
		else if	@MaskChar = 'd' and substring(@NumberMask, @CharI - 1, 2) = '#d' begin
			set @ReverseNumber = @ReverseNumber + reverse(convert(varchar(2), datepart(day, @TranDT)))
			set	@CharI = @CharI - 2
		end
		--	Mask not recognized...
		else	begin
			set @ReverseNumber = @ReverseNumber + @MaskChar
			set	@CharI = @CharI - 1
		end
	end
	
	set	@Number = reverse(@ReverseNumber)
	return
		@Number
end
GO
