SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [FT].[SQLAgent_Category_ID]
(	@Class tinyint,
	@ClassDesc varchar(8),
	@Name sysname)
returns int
as
begin
	declare
		@CategoryID int
	
	if	@Class is null and @ClassDesc is null begin
		set @CategoryID = -1
		return @CategoryID
	end
	
	select
		@CategoryID = CategoryID
	from
		FT.SQLAgent_Categories sac
	where
		coalesce (@Class, sac.CategoryClass) = sac.CategoryClass
	and
		coalesce (@ClassDesc, sac.CategoryClassDesc) = sac.CategoryClassDesc
	and
		@Name = sac.CategoryName
	
	return @CategoryID
end
GO
