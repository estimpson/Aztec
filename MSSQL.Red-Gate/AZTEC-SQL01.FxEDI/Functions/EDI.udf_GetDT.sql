SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE function [EDI].[udf_GetDT]
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
			when 'CCYYMMDDHHMM' then
				convert(datetime, left(@RawValue, 8) + ' ' + coalesce(nullif(substring(@RawValue, 9, 2) + ':' + substring(@RawValue, 11, 2), ':'), ''))
			when 'YYMMDDHHMM' then
				convert(datetime, left(@RawValue, 6) + ' ' + coalesce(nullif(substring(@RawValue, 7, 2) + ':' + substring(@RawValue, 9, 2), ':'), ''))
			when 'CCYYMMDD' then
				convert(datetime, @RawValue)
					when 'YYMMDD' then
				convert(datetime, @RawValue)
			when 'CCYYWW' then
				dateadd(wk, convert(int, substring(@RawValue, 5, 2)), convert (datetime, substring (@RawValue, 1, 4) + '0101') + (1 - datepart (dw, convert (datetime, substring (@RawValue, 1, 4) + '0101'))))
		end
--- </Body>

---	<Return>
	return
		@Result
end



GO
