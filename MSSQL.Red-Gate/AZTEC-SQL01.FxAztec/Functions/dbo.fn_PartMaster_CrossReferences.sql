SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[fn_PartMaster_CrossReferences]
()
returns
	@partCrossReferences table
(	PartCode varchar(25)
,	CrossReferences varchar(max)
)
as
begin
--- <Body>
	declare
		parts cursor local forward_only
	for  
	select distinct
		PartCode
	from
		dbo.PartMaster_CrossReferences pmcr
	where
		Status >= 0

	open
		parts

	while
		1 =	1 begin

		declare
			@partCode varchar(25)
		,	@crossReferences varchar(max) = ''

		fetch
			parts
		into  
			@partCode

		if	@@FETCH_STATUS != 0 begin
			break
		end
	 
		select
			@crossReferences = @crossReferences + ', ' + pmcr.CategoryName + ': ' + pmcr.CrossReference
		from
			dbo.PartMaster_CrossReferences pmcr
		where
			pmcr.PartCode = @partCode

		set	@crossReferences = substring(@crossReferences, 3, len(@crossReferences))

		insert
			@partCrossReferences
		(	PartCode
		,	CrossReferences
		)
		select
			@partCode
		,	@crossReferences
	end

	close
		parts
	deallocate
		parts
--- </Body>

---	<Return>
	return
end
GO
