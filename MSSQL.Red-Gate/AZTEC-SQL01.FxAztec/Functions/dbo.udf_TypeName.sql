SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[udf_TypeName]
(	@TypeTable sysname
,	@TypeValue int)
returns	sysname
as
begin
	declare
		@TypeName sysname
	
	select
		@TypeName = TypeName
	from
		FT.TypeDefn
	where
		TypeTable = @TypeTable
		and TypeColumn = 'Type'
		and TypeCode = @TypeValue
	
	return
		@TypeName
end
GO
