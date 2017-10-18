SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create function [FT].[fn_CamelCase]
(	@inputString nvarchar(max)
)
returns nvarchar(max)
as
begin
--- <Body>
/*	Find all underscores in the input string. */
	while
		1 = 1 begin
	
		declare
			@underscoreIndex bigint
		
		set @underscoreIndex = patindex('%[_]%', @inputString)
		
		if	not (@underscoreIndex > 0) begin
			break
		end
		
		set	@inputString =
				left(@inputString, @underscoreIndex - 1)
				+ space(1)
				+ upper(substring(@inputString, @underscoreIndex + 1, 1))
				+ substring(@inputString, @underscoreIndex + 2, len(@inputString))
	end
	
/*	Find all word separators in input string. */
	declare
		@offset bigint
	
	select
		@offset = 1
	
	while
		1 = 1 begin
	
		declare
			@separatorIndex bigint
		
		set @separatorIndex = patindex('%[>.]%', substring(@inputString, @offset, len(@inputString)))
		
		if	not (@separatorIndex > 0) begin
			break
		end
		
		set	@inputString =
				left(@inputString, @separatorIndex + @offset - 1)
				+ upper(substring(@inputString, @separatorIndex + @offset, 1))
				+ substring(@inputString, @separatorIndex + @offset + 1, len(@inputString))
		
		set	@offset = @offset + @separatorIndex
	end
--- </Body>

---	<Return>
	return
		@inputString
end

GO
