SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE function [dbo].[fn_SplitStringToArray]
(	@InputString varchar(max)
,	@Splitter varchar(max)
,	@Index int
)
returns varchar(max)
as
begin
--- <Body>
	declare
		@value varchar(max)
	
	select
		@value = Value
	from
		dbo.fn_SplitStringToRows(@InputString, @Splitter)
	where
		(	ID = @Index
		) or
		(	ID =
			(	select
					max(ID)
				from
					dbo.fn_SplitStringToRows(@InputString, @Splitter)
			) + @Index
		)
	
---	<Return>
	return
		@value
end
GO
