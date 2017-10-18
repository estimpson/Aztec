SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[fn_SplitStringToRows]
(	@InputString varchar(8000)
,	@Splitter varchar(8000)
)
returns @valueRows table
(	ID int not null IDENTITY(1, 1) primary key
,	Value varchar(8000)
)
as
begin
--- <Body>
	while charindex(@Splitter, @InputString) > 0 begin
		insert
			@ValueRows
		(	value
		)
		values
		(	substring(@InputString, 1, charindex(@Splitter, @InputString) -1)
		)
		
		set	@InputString = substring(@InputString, charindex(@Splitter, @InputString) + datalength(@Splitter), 8000)
	end

	insert
		@ValueRows
	(	value
	)
	values
	(	@InputString
	)--- </Body>

---	<Return>
	return
end
GO
