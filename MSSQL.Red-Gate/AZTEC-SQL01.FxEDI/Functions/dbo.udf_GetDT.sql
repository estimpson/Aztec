SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE function [dbo].[udf_GetDT]
(
	@Format varchar(12)
,	@RawValue varchar(12)
)
returns datetime
as
begin
--- <Body>
	declare
		@Result datetime
	
	set	@Result =
		case @Format
			when 'CCYYMMDD' then
				convert(datetime, @RawValue)
			when 'YYMMDD' then
				convert(datetime, @RawValue)
			when 'CCYYMMDDHHMM' then
				CONVERT(DATETIME, SUBSTRING(@RawValue,1,8)+ SPACE (1)+ SUBSTRING(@RawValue,9,2) + ':' +  SUBSTRING(@RawValue,11,2)+ ':00')
			when 'CCYYWW' then
				dateadd(wk, convert(int, substring(@RawValue, 5, 2)), convert (datetime, substring (@RawValue, 1, 4) + '0101') + (1 - datepart (dw, convert (datetime, substring (@RawValue, 1, 4) + '0101'))))
		end
--- </Body>

---	<Return>
	return
		@Result
end



GO
