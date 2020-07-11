
/*
Create ScalarFunction.FxSYS.dbo.fn_CamelCase.sql
*/

use FxSYS
go


if objectproperty(object_id('dbo.fn_CamelCase'), 'IsScalarFunction') = 1 begin
	drop function dbo.fn_CamelCase
end
go


create function dbo.fn_CamelCase
(	@inputString nvarchar(max)
)
returns nvarchar(max)
as begin
	--- <Body>
	/*	Find all underscores in the input string. */
	while 1 = 1 begin
		declare @underscoreIndex bigint

		set @underscoreIndex = patindex('%[_]%', @inputString)

		if not (@underscoreIndex > 0) begin
			break
		end

		set @inputString
			= left(@inputString, @underscoreIndex - 1) + space(1)
			  + upper(substring(@inputString, @underscoreIndex + 1, 1))
			  + substring(@inputString, @underscoreIndex + 2, len(@inputString))
	end

	/*	Find all word separators in input string. */
	declare @offset bigint

	select @offset = 1

	while 1 = 1 begin
		declare @separatorIndex bigint

		set @separatorIndex = patindex('%[>.]%', substring(@inputString, @offset, len(@inputString)))

		if not (@separatorIndex > 0) begin
			break
		end

		set @inputString
			= left(@inputString, @separatorIndex + @offset - 1)
			  + upper(substring(@inputString, @separatorIndex + @offset, 1))
			  + substring(@inputString, @separatorIndex + @offset + 1, len(@inputString))
		set @offset = @offset + @separatorIndex
	end

	--- </Body>

	---	<Return>
	return @inputString
end
go

select dbo.fn_CamelCase('x_y')
go

