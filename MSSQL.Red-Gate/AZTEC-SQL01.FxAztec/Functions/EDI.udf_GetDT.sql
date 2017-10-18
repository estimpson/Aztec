SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [EDI].[udf_GetDT]
(
	@Format varchar(12)
,	@RawValue varchar(8)
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
			when 'CCYYWW' then
				dateadd(wk, convert(int, substring(@RawValue, 5, 2)), convert (datetime, substring (@RawValue, 1, 4) + '0101') + (1 - datepart (dw, convert (datetime, substring (@RawValue, 1, 4) + '0101'))))
		end
--- </Body>

---	<Return>
	return
		@Result
end
GO
