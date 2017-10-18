SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[udf_GetTrailingDigits]
(
	@MixedValue varchar(1000)
)
returns varchar(1000)
as
begin
--- <Body>

	declare
		@Digits varchar(1000)
	
	set
		@Digits =
		case
			when @MixedValue not like '%[^0-9]%' then @MixedValue
		 	else reverse(case when patindex('%[^0-9]%', reverse(@MixedValue)) > 1 then left(reverse(@MixedValue), patindex('%[^0-9]%', reverse(@MixedValue)) - 1) end)
		end
--- </Body>

--- <Return>
	return
		@Digits
end
GO
