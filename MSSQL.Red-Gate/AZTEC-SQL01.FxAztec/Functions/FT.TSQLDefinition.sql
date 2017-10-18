SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [FT].[TSQLDefinition]
(	@ObjectName sysname
)
returns nvarchar(max)
as
begin
--- <Body>
	declare
		@syntax nvarchar(max)
	
	set	@syntax = ''

	select
		@syntax = @syntax + text
	from
		syscomments
	where
		id = object_id(@ObjectName)
--- </Body>

---	<Return>
	return
		@syntax
end
GO
